using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using fruit_api.DTOs;
using fruit_api.Services.Interfaces;
using System.Security.Claims;

namespace fruit_api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReturnController : ControllerBase
{
    private readonly IReturnService _returnService;
    private readonly ILogger<ReturnController> _logger;

    public ReturnController(IReturnService returnService, ILogger<ReturnController> logger)
    {
        _returnService = returnService;
        _logger = logger;
    }

    // 1. Kiểm tra đơn hàng có được trả không
    [HttpGet("can-return/{orderId}")]
    [Authorize]
    public async Task<IActionResult> CanReturn(string orderId)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
            return Unauthorized(new { success = false, message = "Chưa đăng nhập" });

        var canReturn = await _returnService.CanReturnOrderAsync(userId, orderId);
        return Ok(new { success = true, canReturn = canReturn });
    }

    // 2. Tạo yêu cầu trả hàng - SỬA: [FromForm] để nhận file upload
    [HttpPost("create")]
    [Authorize]
    public async Task<IActionResult> CreateReturnRequest([FromForm] CreateReturnRequestDto dto)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Chưa đăng nhập" });

            var result = await _returnService.CreateReturnRequestAsync(userId, dto);

            if (result == null)
                return BadRequest(new { success = false, message = "Không thể tạo yêu cầu trả hàng" });

            return Ok(new
            {
                success = true,
                message = "Yêu cầu trả hàng đã được gửi",
                data = result
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi tạo yêu cầu trả hàng");
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    // 3. Lấy danh sách yêu cầu của tôi
    [HttpGet("my-returns")]
    [Authorize]
    public async Task<IActionResult> GetMyReturns()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
            return Unauthorized(new { success = false, message = "Chưa đăng nhập" });

        var returns = await _returnService.GetUserReturnRequestsAsync(userId);
        return Ok(new { success = true, data = returns });
    }

    // 4. Lấy chi tiết yêu cầu
    [HttpGet("detail/{returnId}")]
    [Authorize]
    public async Task<IActionResult> GetReturnDetail(string returnId)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var role = User.FindFirst(ClaimTypes.Role)?.Value;

        if (string.IsNullOrEmpty(userId))
            return Unauthorized(new { success = false, message = "Chưa đăng nhập" });

        var returnRequest = await _returnService.GetReturnRequestByIdAsync(returnId, userId, role);

        if (returnRequest == null)
            return NotFound(new { success = false, message = "Không tìm thấy yêu cầu" });

        return Ok(new { success = true, data = returnRequest });
    }

    // 5. Lấy returnId theo orderId
    [HttpGet("by-order/{orderId}")]
    [Authorize]
    public async Task<IActionResult> GetReturnByOrderId(string orderId)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var role = User.FindFirst(ClaimTypes.Role)?.Value;

        if (string.IsNullOrEmpty(userId))
            return Unauthorized(new { success = false, message = "Chưa đăng nhập" });

        var returnRequest = await _returnService.GetReturnByOrderIdAsync(orderId, userId, role);

        if (returnRequest == null)
            return Ok(new { success = true, returnId = (string?)null });

        return Ok(new { success = true, returnId = returnRequest.ReturnId });
    }

    // 6. Admin xử lý yêu cầu (duyệt/từ chối)
    [HttpPost("process")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> ProcessReturnRequest([FromBody] ProcessReturnRequestDto dto)
    {
        try
        {
            var adminId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(adminId))
                return Unauthorized(new { success = false, message = "Chưa đăng nhập" });

            var result = await _returnService.ProcessReturnRequestAsync(adminId, dto);

            if (result == null)
                return BadRequest(new { success = false, message = "Xử lý thất bại" });

            var message = dto.IsApproved ? "Đã chấp nhận trả hàng" : "Đã từ chối trả hàng";

            return Ok(new { success = true, message = message, data = result });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi xử lý yêu cầu trả hàng");
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    // 7. Admin xác nhận đã nhận lại hàng
    [HttpPost("complete/{returnId}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> CompleteReturn(string returnId)
    {
        try
        {
            var result = await _returnService.CompleteReturnAsync(returnId);

            if (result == null)
                return BadRequest(new { success = false, message = "Xác nhận thất bại" });

            return Ok(new
            {
                success = true,
                message = "Đã xác nhận nhận lại hàng, tiền sẽ được hoàn trả và tồn kho đã được cập nhật", 
                data = result
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi xác nhận nhận lại hàng");
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    // 8. Hủy yêu cầu trả hàng
    [HttpPost("cancel/{returnId}")]
    [Authorize]
    public async Task<IActionResult> CancelReturnRequest(string returnId)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
            return Unauthorized(new { success = false, message = "Chưa đăng nhập" });

        var result = await _returnService.CancelReturnRequestAsync(userId, returnId);

        if (!result)
            return BadRequest(new { success = false, message = "Không thể hủy yêu cầu này" });

        return Ok(new { success = true, message = "Đã hủy yêu cầu trả hàng" });
    }

    // 9. Admin lấy tất cả yêu cầu
    [HttpGet("all")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> GetAllReturns([FromQuery] string? status = null)
    {
        var returns = await _returnService.GetAllReturnRequestsAsync(status);
        return Ok(new { success = true, data = returns });
    }
}
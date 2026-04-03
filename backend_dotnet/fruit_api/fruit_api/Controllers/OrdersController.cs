using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using fruit_api.DTOs.Order;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;
    private readonly IRealTimeService _realTimeService;

    public OrdersController(IOrderService orderService, IRealTimeService realTimeService)
    {
        _orderService = orderService;
        _realTimeService = realTimeService;
    }

    private string GetUserId()
    {
        return User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();
    }

    private string GetUserRole()
    {
        return User.FindFirst(ClaimTypes.Role)?.Value ?? "user";
    }

    /// <summary>
    /// Lấy danh sách đơn hàng của người dùng hiện tại
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetMyOrders()
    {
        try
        {
            var userId = GetUserId();
            var orders = await _orderService.GetUserOrdersAsync(userId);
            return Ok(orders);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Lấy tất cả đơn hàng (không lọc theo trạng thái) - chỉ admin
    /// </summary>
    [HttpGet("admin/all")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> GetAllOrders()
    {
        try
        {
            var orders = await _orderService.GetAllOrdersAsync();
            return Ok(orders);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Lấy đơn hàng theo trạng thái (chỉ admin)
    /// </summary>
    [HttpGet("admin/status/{status}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> GetOrdersByStatus(string status)
    {
        try
        {
            var orders = await _orderService.GetAllOrdersAsync(status);
            return Ok(orders);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Lấy chi tiết đơn hàng theo ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetOrderById(string id)
    {
        try
        {
            var order = await _orderService.GetOrderByIdAsync(id);
            if (order == null)
                return NotFound(new { message = "Order not found" });

            var userId = GetUserId();
            var userRole = GetUserRole();

            if (order.UserId != userId && userRole != "admin")
                return Forbid();

            return Ok(order);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Tạo đơn hàng từ giỏ hàng
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> CreateOrder(CreateOrderDto createOrderDto)
    {
        try
        {
            var userId = GetUserId();
            if (createOrderDto.ShippingFee == 0)
            {
                createOrderDto.ShippingFee = 25000;
            }
            var order = await _orderService.CreateOrderAsync(userId, createOrderDto);
            return Ok(order);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Mua ngay (tạo đơn hàng từ sản phẩm đơn lẻ)
    /// </summary>
    [HttpPost("buy-now")]
    public async Task<IActionResult> BuyNow([FromBody] BuyNowDto buyNowDto)
    {
        try
        {
            var userId = GetUserId();
            if (buyNowDto.ShippingFee == 0)
            {
                buyNowDto.ShippingFee = 25000;
            }
            var order = await _orderService.BuyNowAsync(userId, buyNowDto);
            return Ok(order);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Cập nhật trạng thái đơn hàng (chỉ admin)
    /// </summary>
    [HttpPut("{id}/status")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> UpdateOrderStatus(string id, UpdateOrderStatusDto updateDto)
    {
        try
        {
            var order = await _orderService.UpdateOrderStatusAsync(id, updateDto);
            return Ok(new
            {
                success = true,
                message = "Cập nhật trạng thái thành công",
                order
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    /// <summary>
    /// Hủy đơn hàng (người dùng tự hủy)
    /// </summary>
    [HttpPost("{id}/cancel")]
    public async Task<IActionResult> CancelOrder(string id)
    {
        try
        {
            var userId = GetUserId();
            var order = await _orderService.GetOrderByIdAsync(id);

            if (order == null)
                return NotFound(new { message = "Order not found" });

            if (order.UserId != userId)
                return Forbid();

            await _orderService.CancelOrderAsync(id);
            return Ok(new { message = "Order cancelled successfully" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Test real-time notification (chỉ admin)
    /// </summary>
    [HttpPost("test-notification")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> TestNotification([FromBody] TestNotificationRequest request)
    {
        try
        {
            await _realTimeService.NotifyUserAsync(
                request.UserId,
                "Test",
                request.Message ?? "Test notification from server",
                new { TestData = "Hello from SignalR", Timestamp = DateTime.Now }
            );

            return Ok(new { success = true, message = "Notification sent successfully" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }
}

public class TestNotificationRequest
{
    public string UserId { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}
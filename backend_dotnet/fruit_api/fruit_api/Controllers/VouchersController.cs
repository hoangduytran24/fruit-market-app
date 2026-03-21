using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using fruit_api.DTOs.Voucher;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[Route("api/vouchers")]
[ApiController]
public class VouchersController : ControllerBase
{
    private readonly IVoucherService _voucherService;

    public VouchersController(IVoucherService voucherService)
    {
        _voucherService = voucherService;
    }

    // ==================== ADMIN APIs ====================

    /// <summary>
    /// [ADMIN] Tạo voucher mới
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> CreateVoucher(CreateVoucherDto createDto)
    {
        try
        {
            var voucher = await _voucherService.CreateVoucherAsync(createDto);
            return CreatedAtAction(nameof(GetVoucherById), new { id = voucher.VoucherId }, voucher);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// [ADMIN] Lấy danh sách tất cả voucher
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> GetAllVouchers()
    {
        var vouchers = await _voucherService.GetAllVouchersAsync();
        return Ok(vouchers);
    }

    /// <summary>
    /// [ADMIN] Lấy chi tiết voucher theo ID
    /// </summary>
    [HttpGet("{id}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> GetVoucherById(string id)
    {
        var voucher = await _voucherService.GetVoucherByIdAsync(id);
        if (voucher == null)
            return NotFound(new { message = "Không tìm thấy voucher" });

        return Ok(voucher);
    }

    /// <summary>
    /// [ADMIN] Cập nhật voucher
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> UpdateVoucher(string id, UpdateVoucherDto updateDto)
    {
        try
        {
            var updatedVoucher = await _voucherService.UpdateVoucherAsync(id, updateDto);
            return Ok(updatedVoucher);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// [ADMIN] Xóa voucher
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> DeleteVoucher(string id)
    {
        try
        {
            var result = await _voucherService.DeleteVoucherAsync(id);
            if (result)
                return Ok(new { message = "Xóa voucher thành công" });

            return NotFound(new { message = "Không tìm thấy voucher" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// [ADMIN] Bật/tắt trạng thái voucher
    /// </summary>
    [HttpPatch("{id}/status")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> ToggleVoucherStatus(string id)
    {
        try
        {
            var result = await _voucherService.ToggleVoucherStatusAsync(id);
            if (result)
                return Ok(new { message = "Cập nhật trạng thái voucher thành công" });

            return NotFound(new { message = "Không tìm thấy voucher" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // ==================== USER APIs ====================

    /// <summary>
    /// [USER] Lấy danh sách voucher khả dụng
    /// </summary>
    [HttpGet("available")]
    [AllowAnonymous]
    public async Task<IActionResult> GetAvailableVouchers()
    {
        var vouchers = await _voucherService.GetAvailableVouchersAsync();
        return Ok(vouchers);
    }

    /// <summary>
    /// [USER] Áp dụng voucher (QUAN TRỌNG NHẤT)
    /// </summary>
    [HttpPost("apply")]
    [Authorize]
    public async Task<IActionResult> ApplyVoucher(ApplyVoucherDto applyDto)
    {
        try
        {
            var result = await _voucherService.ApplyVoucherAsync(applyDto);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// [USER] Lưu voucher (kiểu Shopee)
    /// </summary>
    [HttpPost("save")]
    [Authorize]
    public async Task<IActionResult> SaveVoucher(SaveUserVoucherDto saveDto)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Không tìm thấy thông tin người dùng" });

            var result = await _voucherService.SaveVoucherForUserAsync(userId, saveDto.VoucherCode);
            if (result)
                return Ok(new { message = "Lưu voucher thành công" });

            return BadRequest(new { message = "Không thể lưu voucher" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// [USER] Lấy danh sách voucher đã lưu
    /// </summary>
    [HttpGet("my-vouchers")]
    [Authorize]
    public async Task<IActionResult> GetMySavedVouchers()
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Không tìm thấy thông tin người dùng" });

            var vouchers = await _voucherService.GetUserSavedVouchersAsync(userId);
            return Ok(vouchers);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// [USER] Sử dụng voucher đã lưu
    /// </summary>
    [HttpPost("use/{userVoucherId}")]
    [Authorize]
    public async Task<IActionResult> UseSavedVoucher(string userVoucherId)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Không tìm thấy thông tin người dùng" });

            var result = await _voucherService.UseSavedVoucherAsync(userId, userVoucherId);
            if (result)
                return Ok(new { message = "Sử dụng voucher thành công" });

            return BadRequest(new { message = "Không thể sử dụng voucher" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
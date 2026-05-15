using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using fruit_api.DTOs.Auth;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "admin")]
public class AdminController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AdminController> _logger;

    public AdminController(IAuthService authService, ILogger<AdminController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    // GET: api/admin/locked-users
    [HttpGet("locked-users")]
    public async Task<IActionResult> GetLockedUsers()
    {
        try
        {
            var users = await _authService.GetLockedUsersAsync();
            return Ok(new { success = true, data = users, count = users.Count });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy danh sách tài khoản bị khóa");
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    // POST: api/admin/lock-account
    [HttpPost("lock-account")]
    public async Task<IActionResult> LockAccount([FromBody] LockAccountDto dto)
    {
        if (string.IsNullOrEmpty(dto.UserId))
        {
            return BadRequest(new { success = false, message = "UserId không được để trống" });
        }

        try
        {
            var result = await _authService.LockUserAccountAsync(dto.UserId, dto.Reason);

            if (result)
            {
                _logger.LogInformation($"Admin đã khóa tài khoản {dto.UserId}");
                return Ok(new { success = true, message = "Đã khóa tài khoản thành công" });
            }
            else
            {
                return BadRequest(new { success = false, message = "Tài khoản đã bị khóa trước đó hoặc không thể khóa" });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Lỗi khi khóa tài khoản {dto.UserId}");
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    // POST: api/admin/unlock-account
    [HttpPost("unlock-account")]
    public async Task<IActionResult> UnlockAccount([FromBody] LockAccountDto dto)
    {
        if (string.IsNullOrEmpty(dto.UserId))
        {
            return BadRequest(new { success = false, message = "UserId không được để trống" });
        }

        try
        {
            var result = await _authService.UnlockUserAccountAsync(dto.UserId);

            if (result)
            {
                _logger.LogInformation($"Admin đã mở khóa tài khoản {dto.UserId}");
                return Ok(new { success = true, message = "Đã mở khóa tài khoản thành công" });
            }
            else
            {
                return BadRequest(new { success = false, message = "Tài khoản đã được mở khóa trước đó" });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Lỗi khi mở khóa tài khoản {dto.UserId}");
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }
}
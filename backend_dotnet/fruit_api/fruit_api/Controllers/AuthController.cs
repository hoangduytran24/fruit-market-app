using Microsoft.AspNetCore.Mvc;
using fruit_api.DTOs.Auth;
using fruit_api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace fruit_api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger; // 👈 THÊM logger

    public AuthController(IAuthService authService, ILogger<AuthController> logger) // 👈 SỬA constructor
    {
        _authService = authService;
        _logger = logger;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterDto registerDto)
    {
        try
        {
            var result = await _authService.RegisterAsync(registerDto);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginDto loginDto)
    {
        try
        {
            var result = await _authService.LoginAsync(loginDto);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetCurrentUser()
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Invalid token" });
            }

            var user = await _authService.GetUserByIdAsync(userId);

            if (user == null)
            {
                return NotFound(new { message = "User not found" });
            }

            return Ok(user);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // ===============================
    // 🆕 THÊM ENDPOINT NÀY - KIỂM TRA TRẠNG THÁI TÀI KHOẢN
    // ===============================
    [Authorize]
    [HttpGet("check-status")]
    public async Task<IActionResult> CheckAccountStatus()
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { success = false, message = "Không xác định được người dùng" });
            }

            var result = await _authService.CheckAccountStatusAsync(userId);

            if (!result.IsActive)
            {
                _logger.LogWarning($"Tài khoản {userId} đã bị khóa, status: {result.Status}");

                return StatusCode(StatusCodes.Status403Forbidden, new
                {
                    success = false,
                    message = "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ.",
                    code = "ACCOUNT_LOCKED",
                    status = result.Status
                });
            }

            return Ok(new
            {
                success = true,
                message = "Tài khoản đang hoạt động",
                data = result
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi kiểm tra trạng thái tài khoản");
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }
}
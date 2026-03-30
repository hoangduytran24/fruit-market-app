using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using fruit_api.DTOs.User;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "admin")]
public class UserManagementController : ControllerBase
{
    private readonly IUserManagementService _userService;

    public UserManagementController(IUserManagementService userService)
    {
        _userService = userService;
    }

    // 1. Lấy TẤT CẢ user (không search, có thể lọc role)
    // GET: api/UserManagement/all?role=admin
    [HttpGet("all")]
    public async Task<IActionResult> GetAllUsers([FromQuery] string? role)
    {
        var users = await _userService.GetUsersAsync(null, role);
        return Ok(users);
    }

    // 2. TÌM KIẾM user (theo tên, email, SĐT) + lọc role
    // GET: api/UserManagement/search?keyword=hoàng&role=admin
    [HttpGet("search")]
    public async Task<IActionResult> SearchUsers(
        [FromQuery] string keyword,
        [FromQuery] string? role)
    {
        if (string.IsNullOrEmpty(keyword))
            return BadRequest(new { message = "Keyword is required for search" });

        var users = await _userService.GetUsersAsync(keyword, role);
        return Ok(users);
    }

    // 3. Xem chi tiết user theo ID
    // GET: api/UserManagement/{id}
    [HttpGet("{userId}")]
    public async Task<IActionResult> GetUserById(string userId)
    {
        var user = await _userService.GetUserByIdAsync(userId);
        if (user == null)
            return NotFound(new { message = "User not found" });
        return Ok(user);
    }

    // 4. Khóa/mở tài khoản
    // PATCH: api/UserManagement/{id}/status
    [HttpPatch("{userId}/status")]
    public async Task<IActionResult> UpdateUserStatus(string userId, [FromBody] UpdateUserStatusDto updateDto)
    {
        try
        {
            var user = await _userService.UpdateUserStatusAsync(userId, updateDto);
            return Ok(user);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // 5. Tạo tài khoản admin
    // POST: api/UserManagement/admin
    [HttpPost("admin")]
    public async Task<IActionResult> CreateAdmin([FromBody] CreateAdminDto createAdminDto)
    {
        try
        {
            var admin = await _userService.CreateAdminAsync(createAdminDto);
            return Ok(admin);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
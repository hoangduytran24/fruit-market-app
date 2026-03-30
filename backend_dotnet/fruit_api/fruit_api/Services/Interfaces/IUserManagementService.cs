using fruit_api.DTOs.User;

namespace fruit_api.Services.Interfaces;

public interface IUserManagementService
{
    // Lấy danh sách user (có tìm kiếm và lọc)
    Task<IEnumerable<UserDto>> GetUsersAsync(string? search = null, string? role = null);

    // Xem chi tiết user theo ID
    Task<UserDto?> GetUserByIdAsync(string userId);

    // Khóa/mở tài khoản
    Task<UserDto> UpdateUserStatusAsync(string userId, UpdateUserStatusDto updateDto);

    // Tạo tài khoản admin
    Task<UserDto> CreateAdminAsync(CreateAdminDto createAdminDto);
}
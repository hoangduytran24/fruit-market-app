using fruit_api.DTOs.Auth;

namespace fruit_api.Services.Interfaces;

public interface IAuthService
{
    Task<AuthResponseDto> RegisterAsync(RegisterDto registerDto);
    Task<AuthResponseDto> LoginAsync(LoginDto loginDto);
    Task<AuthResponseDto> GetUserByIdAsync(string userId);
    Task<AccountStatusDto> CheckAccountStatusAsync(string userId);
    Task<bool> LockUserAccountAsync(string userId, string? reason = null);
    Task<bool> UnlockUserAccountAsync(string userId);
    Task<List<AccountStatusDto>> GetLockedUsersAsync();
}
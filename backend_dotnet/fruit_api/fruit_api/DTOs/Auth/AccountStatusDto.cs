namespace fruit_api.DTOs.Auth;

public class AccountStatusDto
{
    public string UserId { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string Role { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

public class LockAccountDto
{
    public string UserId { get; set; } = string.Empty;
    public string? Reason { get; set; }
}
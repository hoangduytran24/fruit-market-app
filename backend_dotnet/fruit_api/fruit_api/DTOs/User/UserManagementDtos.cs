using System.ComponentModel.DataAnnotations;

namespace fruit_api.DTOs.User;

// Response DTO
public class UserDto
{
    public string UserId { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string Role { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public int OrderCount { get; set; }
    public double TotalSpent { get; set; }
}

// Tạo admin
public class CreateAdminDto
{
    [Required]
    public string FullName { get; set; } = string.Empty;

    [Required]
    public string Email { get; set; } = string.Empty;

    public string? Phone { get; set; }

    [Required]
    [MinLength(6)]
    public string Password { get; set; } = string.Empty;
}

// Cập nhật status (khóa/mở)
public class UpdateUserStatusDto
{
    [Required]
    [RegularExpression("^(active|inactive|banned)$")]
    public string Status { get; set; } = string.Empty;
}
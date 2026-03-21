using System.ComponentModel.DataAnnotations;

namespace fruit_api.DTOs.Auth;

public class RegisterDto
{
    [Required(ErrorMessage = "Full name is required")]
    [MaxLength(100, ErrorMessage = "Full name cannot exceed 100 characters")]
    public string FullName { get; set; } = string.Empty;

    [Phone(ErrorMessage = "Invalid phone number")]
    [MaxLength(15, ErrorMessage = "Phone cannot exceed 15 characters")]
    public string? Phone { get; set; }

    [EmailAddress(ErrorMessage = "Invalid email address")]
    [MaxLength(100, ErrorMessage = "Email cannot exceed 100 characters")]
    public string? Email { get; set; }

    [Required(ErrorMessage = "Password is required")]
    [MinLength(6, ErrorMessage = "Password must be at least 6 characters")]
    public string Password { get; set; } = string.Empty;
}
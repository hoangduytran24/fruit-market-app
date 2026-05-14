using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Users")]
public class User
{
    [Key]
    [Column("userId")]
    public string UserId { get; set; } = null!;

    [Required]
    [MaxLength(100)]
    [Column("fullName")]
    public string FullName { get; set; } = string.Empty;

    [MaxLength(15)]
    [Column("phone")]
    public string? Phone { get; set; }

    [MaxLength(100)]
    [Column("email")]
    public string? Email { get; set; }

    [Required]
    [Column("passwordHash")]
    public string PasswordHash { get; set; } = string.Empty;

    [MaxLength(20)]
    [Column("role")]
    public string Role { get; set; } = "customer";

    [MaxLength(20)]
    [Column("status")]
    public string Status { get; set; } = "active";

    [Column("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public Cart? Cart { get; set; }
    public ICollection<Order>? Orders { get; set; }
    public ICollection<Review>? Reviews { get; set; }
    public ICollection<Favorite>? Favorites { get; set; }

    public ICollection<UserVoucher>? UserVouchers { get; set; }
}
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Users")]
public class User
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("userId")]  // Sửa từ user_id thành userId
    public string UserId { get; set; } = null!;

    [Required]
    [MaxLength(100)]
    [Column("fullName")]  // Sửa từ full_name thành fullName
    public string FullName { get; set; } = string.Empty;

    [MaxLength(15)]
    [Column("phone")]  // Giữ nguyên
    public string? Phone { get; set; }

    [MaxLength(100)]
    [Column("email")]  // Giữ nguyên
    public string? Email { get; set; }

    [Required]
    [Column("passwordHash")]  // Sửa từ password_hash thành passwordHash
    public string PasswordHash { get; set; } = string.Empty;

    [MaxLength(20)]
    [Column("role")]  // Giữ nguyên
    public string Role { get; set; } = "customer";

    [MaxLength(20)]
    [Column("status")]  // Giữ nguyên
    public string Status { get; set; } = "active";

    [Column("createdAt")]  // Sửa từ created_at thành createdAt
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public Cart? Cart { get; set; }
    public ICollection<Order>? Orders { get; set; }
    public ICollection<Review>? Reviews { get; set; }
    public ICollection<Favorite>? Favorites { get; set; }

    // THÊM DÒNG NÀY - cho phép user lưu nhiều voucher
    public ICollection<UserVoucher>? UserVouchers { get; set; }
}
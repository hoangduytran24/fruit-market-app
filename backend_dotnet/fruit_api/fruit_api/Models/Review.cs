using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Reviews")]
public class Review
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("reviewId")]  // Sửa từ review_id thành reviewId
    public string ReviewId { get; set; } = null!;

    [Required]
    [Column("userId")]  // Sửa từ user_id thành userId
    public string UserId { get; set; } = null!;

    [Required]
    [Column("productId")]  // Sửa từ product_id thành productId
    public string ProductId { get; set; } = null!;

    [Required]
    [Range(1, 5)]
    [Column("rating")]  // Giữ nguyên
    public int Rating { get; set; }

    [MaxLength(500)]
    [Column("comment")]  // Giữ nguyên
    public string? Comment { get; set; }

    [Column("createdAt")]  // Sửa từ created_at thành createdAt
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public User? User { get; set; }
    public Product? Product { get; set; }
}
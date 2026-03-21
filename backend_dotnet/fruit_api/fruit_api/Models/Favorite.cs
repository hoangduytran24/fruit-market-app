using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Favorites")]
public class Favorite
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("favoriteId")]  // Sửa từ favorite_id thành favoriteId
    public string FavoriteId { get; set; } = null!;

    [Required]
    [Column("userId")]  // Sửa từ user_id thành userId
    public string UserId { get; set; } = null!;

    [Required]
    [Column("productId")]  // Sửa từ product_id thành productId
    public string ProductId { get; set; } = null!;

    [Column("createdAt")]  // Sửa từ created_at thành createdAt
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public User? User { get; set; }
    public Product? Product { get; set; }
}
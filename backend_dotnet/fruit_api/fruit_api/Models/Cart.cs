using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Carts")]
public class Cart
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("cartId")]  // Sửa từ cart_id thành cartId
    public string CartId { get; set; } = null!;

    [Required]
    [Column("userId")]  // Sửa từ user_id thành userId
    public string UserId { get; set; } = null!;

    [Column("createdAt")]  // Sửa từ created_at thành createdAt
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    [Column("updatedAt")]  // Sửa từ updated_at thành updatedAt
    public DateTime UpdatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public User? User { get; set; }
    public ICollection<CartItem>? CartItems { get; set; }
}
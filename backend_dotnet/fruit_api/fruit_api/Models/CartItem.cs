using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("CartItems")]  // Sửa từ Cart_items thành CartItems
public class CartItem
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("cartItemId")]  // Sửa từ cart_item_id thành cartItemId
    public string CartItemId { get; set; } = null!;

    [Required]
    [Column("cartId")]  // Sửa từ cart_id thành cartId
    public string CartId { get; set; } = null!;

    [Required]
    [Column("productId")]  // Sửa từ product_id thành productId
    public string ProductId { get; set; } = null!;

    [Required]
    [Column("quantity")]  // Giữ nguyên
    public int Quantity { get; set; }

    [Required]
    [Column("priceAtTime", TypeName = "decimal(12,2)")]  // Sửa từ price_at_time thành priceAtTime
    public decimal PriceAtTime { get; set; }

    // Navigation properties
    public Cart? Cart { get; set; }
    public Product? Product { get; set; }
}
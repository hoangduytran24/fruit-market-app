using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("CartItems")]
public class CartItem
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("cartItemId")]
    public string CartItemId { get; set; } = null!;

    [Required]
    [Column("cartId")]
    public string CartId { get; set; } = null!;

    [Required]
    [Column("productId")]
    public string ProductId { get; set; } = null!;

    [Required]
    [Column("quantity")]
    public int Quantity { get; set; }

    [Required]
    [Column("priceAtTime", TypeName = "decimal(12,2)")]
    public decimal PriceAtTime { get; set; }

    // Navigation properties
    public Cart? Cart { get; set; }
    public Product? Product { get; set; }
}
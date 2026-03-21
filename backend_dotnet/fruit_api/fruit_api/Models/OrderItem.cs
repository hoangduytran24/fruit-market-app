using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("OrderItems")]  // Sửa từ Order_items thành OrderItems
public class OrderItem
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("orderItemId")]  // Sửa từ order_item_id thành orderItemId
    public string OrderItemId { get; set; } = null!;

    [Required]
    [Column("orderId")]  // Sửa từ order_id thành orderId
    public string OrderId { get; set; } = null!;

    [Required]
    [Column("productId")]  // Sửa từ product_id thành productId
    public string ProductId { get; set; } = null!;

    [Required]
    [Column("quantity")]  // Giữ nguyên
    public int Quantity { get; set; }

    [Required]
    [Column("priceAtTime", TypeName = "decimal(12,2)")]  // Sửa từ price_at_time thành priceAtTime
    public decimal PriceAtTime { get; set; }

    [DatabaseGenerated(DatabaseGeneratedOption.Computed)]
    [Column("subtotal")]  // Giữ nguyên
    public decimal Subtotal { get; private set; }

    // Navigation properties
    public Order? Order { get; set; }
    public Product? Product { get; set; }
}
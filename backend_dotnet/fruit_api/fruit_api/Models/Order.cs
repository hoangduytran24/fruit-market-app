using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Orders")]
public class Order
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("orderId")]  // Sửa từ order_id thành orderId
    public string OrderId { get; set; } = null!;

    [Required]
    [Column("userId")]  // Sửa từ user_id thành userId
    public string UserId { get; set; } = null!;

    [Column("totalAmount", TypeName = "decimal(12,2)")]  // Sửa từ total_amount thành totalAmount
    public decimal TotalAmount { get; set; } = 0;

    [Column("discountAmount", TypeName = "decimal(12,2)")]  // Sửa từ discount_amount thành discountAmount
    public decimal DiscountAmount { get; set; } = 0;

    [DatabaseGenerated(DatabaseGeneratedOption.Computed)]
    [Column("finalAmount")]  // Sửa từ final_amount thành finalAmount
    public decimal FinalAmount { get; private set; }

    [MaxLength(30)]
    [Column("status")]  // Giữ nguyên
    public string Status { get; set; } = "pending";

    [MaxLength(50)]
    [Column("paymentMethod")]  // Sửa từ payment_method thành paymentMethod
    public string? PaymentMethod { get; set; }

    [Required]
    [MaxLength(255)]
    [Column("deliveryAddress")]  // Sửa từ delivery_address thành deliveryAddress
    public string DeliveryAddress { get; set; } = string.Empty;

    [Column("createdAt")]  // Sửa từ created_at thành createdAt
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public User? User { get; set; }
    public ICollection<OrderItem>? OrderItems { get; set; }
    public Payment? Payment { get; set; }
    public OrderVoucher? OrderVoucher { get; set; }
}
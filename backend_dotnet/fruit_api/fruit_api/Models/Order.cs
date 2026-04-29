using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Orders")]
public class Order
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("orderId")]
    public string OrderId { get; set; } = null!;

    [Required]
    [Column("userId")]
    public string UserId { get; set; } = null!;

    [Column("totalAmount", TypeName = "decimal(12,2)")]
    public decimal TotalAmount { get; set; } = 0;

    [Column("discountAmount", TypeName = "decimal(12,2)")]
    public decimal DiscountAmount { get; set; } = 0;

    [DatabaseGenerated(DatabaseGeneratedOption.Computed)]
    [Column("finalAmount")]
    public decimal FinalAmount { get; private set; }

    [MaxLength(30)]
    [Column("orderStatus")]
    public string Status { get; set; } = "pending";

    [MaxLength(50)]
    [Column("paymentMethod")]
    public string? PaymentMethod { get; set; }

    [Required]
    [MaxLength(255)]
    [Column("deliveryAddress")]
    public string DeliveryAddress { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    [Column("receiverName")]
    public string ReceiverName { get; set; } = string.Empty;

    [Required]
    [MaxLength(15)]
    [Column("receiverPhone")]
    public string ReceiverPhone { get; set; } = string.Empty;

    [Column("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public User? User { get; set; }
    public ICollection<OrderItem>? OrderItems { get; set; }
    public Payment? Payment { get; set; }
    public OrderVoucher? OrderVoucher { get; set; }
}
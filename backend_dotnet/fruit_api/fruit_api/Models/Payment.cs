using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Payments")]
public class Payment
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("paymentId")]  // Sửa từ payment_id thành paymentId
    public string PaymentId { get; set; } = null!;

    [Required]
    [Column("orderId")]  // Sửa từ order_id thành orderId
    public string OrderId { get; set; } = null!;

    [Required]
    [Column("amount", TypeName = "decimal(12,2)")]  // Giữ nguyên
    public decimal Amount { get; set; }

    [MaxLength(50)]
    [Column("paymentMethod")]  // Sửa từ payment_method thành paymentMethod
    public string? PaymentMethod { get; set; }

    [MaxLength(30)]
    [Column("paymentStatus")]  // Sửa từ payment_status thành paymentStatus
    public string PaymentStatus { get; set; } = "unpaid";

    [MaxLength(100)]
    [Column("transactionCode")]  // Sửa từ transaction_code thành transactionCode
    public string? TransactionCode { get; set; }

    [Column("paidAt")]  // Sửa từ paid_at thành paidAt
    public DateTime? PaidAt { get; set; }

    // Navigation properties
    public Order? Order { get; set; }
}
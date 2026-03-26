using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Payments")]
public class Payment
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("paymentId")]
    public string PaymentId { get; set; } = null!;

    [Required]
    [Column("orderId")]
    public string OrderId { get; set; } = null!;

    [Required]
    [Column("amount", TypeName = "decimal(12,2)")]
    public decimal Amount { get; set; }

    [MaxLength(50)]
    [Column("paymentMethod")]
    public string? PaymentMethod { get; set; }

    [MaxLength(30)]
    [Column("paymentStatus")]
    public string PaymentStatus { get; set; } = "unpaid";

    [MaxLength(100)]
    [Column("transactionCode")]
    public string? TransactionCode { get; set; }

    [Column("paidAt")]
    public DateTime? PaidAt { get; set; }

    // MoMo fields
    [MaxLength(100)]
    [Column("momoRequestId")]
    public string? MomoRequestId { get; set; }

    [MaxLength(50)]
    [Column("momoPartnerCode")]
    public string? MomoPartnerCode { get; set; }

    [MaxLength(500)]
    [Column("qrCodeUrl")]
    public string? QrCodeUrl { get; set; }

    // Navigation properties
    [ForeignKey("OrderId")]
    public Order? Order { get; set; }
}
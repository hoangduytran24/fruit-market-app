using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("PendingTransactions")]
public class PendingTransaction
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Column("orderId")]
    public string OrderId { get; set; } = null!;

    [Column("paymentId")]
    public string PaymentId { get; set; } = null!;

    [Column("amount", TypeName = "decimal(12,2)")]
    public decimal Amount { get; set; }

    [MaxLength(10)]
    [Column("bankCode")]
    public string? BankCode { get; set; }

    [MaxLength(100)]
    [Column("transactionCode")]
    public string? TransactionCode { get; set; }

    [MaxLength(20)]
    [Column("status")]
    public string Status { get; set; } = "pending";

    [Column("checkCount")]
    public int CheckCount { get; set; } = 0;

    [Column("checkedAt")]
    public DateTime? CheckedAt { get; set; }

    [Column("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    [ForeignKey("OrderId")]
    public Order? Order { get; set; }

    [ForeignKey("PaymentId")]
    public Payment? Payment { get; set; }
}
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("ReturnRequests")]
public class ReturnRequest
{
    [Key]
    [Column("returnId")]
    [StringLength(20)]
    public string ReturnId { get; set; } = null!;

    [Required]
    [Column("orderId")]
    public string OrderId { get; set; } = null!;

    [Required]
    [Column("userId")]
    public string UserId { get; set; } = null!;

    [Required]
    [MaxLength(255)]
    [Column("reason")]
    public string Reason { get; set; } = string.Empty;

    [Column("description")]
    public string? Description { get; set; }

    [MaxLength(500)]
    [Column("imageUrl")]
    public string? ImageUrl { get; set; }

    [Column("status")]
    [StringLength(30)]
    public string Status { get; set; } = "pending";

    [Column("refundAmount", TypeName = "decimal(12,2)")]
    public decimal RefundAmount { get; set; }

    [Column("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    [Column("approvedAt")]
    public DateTime? ApprovedAt { get; set; }

    [Column("completedAt")]
    public DateTime? CompletedAt { get; set; }

    [Column("rejectedAt")]
    public DateTime? RejectedAt { get; set; }

    [MaxLength(500)]
    [Column("rejectReason")]
    public string? RejectReason { get; set; }

    // Navigation properties
    [ForeignKey("OrderId")]
    public Order? Order { get; set; }

    [ForeignKey("UserId")]
    public User? User { get; set; }
}
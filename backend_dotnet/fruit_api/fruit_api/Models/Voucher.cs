using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Vouchers")]
public class Voucher
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("voucherId")]
    public string VoucherId { get; set; } = null!;

    [Required]
    [MaxLength(50)]
    [Column("voucherCode")]
    public string VoucherCode { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    [Column("discountType")]
    public string DiscountType { get; set; } = string.Empty;

    [Required]
    [Column("discountValue", TypeName = "decimal(12,2)")]
    public decimal DiscountValue { get; set; }

    [Column("minOrderValue", TypeName = "decimal(12,2)")]
    public decimal MinOrderValue { get; set; } = 0;

    [Column("maxDiscountValue", TypeName = "decimal(12,2)")]
    public decimal? MaxDiscountValue { get; set; }

    [Required]
    [Column("quantity")]
    public int Quantity { get; set; }

    [Column("usedQuantity")]
    public int UsedQuantity { get; set; } = 0;

    [Column("startDate")]
    public DateTime? StartDate { get; set; }

    [Column("endDate")]
    public DateTime? EndDate { get; set; }

    [MaxLength(20)]
    [Column("status")]
    public string Status { get; set; } = "active";

    // Navigation properties
    public OrderVoucher? OrderVoucher { get; set; }

    public ICollection<UserVoucher>? UserVouchers { get; set; }
}
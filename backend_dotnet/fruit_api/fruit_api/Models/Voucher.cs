using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Vouchers")]
public class Voucher
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("voucherId")]  // Sửa từ voucher_id thành voucherId
    public string VoucherId { get; set; } = null!;

    [Required]
    [MaxLength(50)]
    [Column("voucherCode")]  // Sửa từ voucher_code thành voucherCode
    public string VoucherCode { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    [Column("discountType")]  // Sửa từ discount_type thành discountType
    public string DiscountType { get; set; } = string.Empty;

    [Required]
    [Column("discountValue", TypeName = "decimal(12,2)")]  // Sửa từ discount_value thành discountValue
    public decimal DiscountValue { get; set; }

    [Column("minOrderValue", TypeName = "decimal(12,2)")]  // Sửa từ min_order_value thành minOrderValue
    public decimal MinOrderValue { get; set; } = 0;

    [Column("maxDiscountValue", TypeName = "decimal(12,2)")]  // Sửa từ max_discount_value thành maxDiscountValue
    public decimal? MaxDiscountValue { get; set; }

    [Required]
    [Column("quantity")]  // Giữ nguyên
    public int Quantity { get; set; }

    [Column("usedQuantity")]  // Sửa từ used_quantity thành usedQuantity
    public int UsedQuantity { get; set; } = 0;

    [Column("startDate")]  // Sửa từ start_date thành startDate
    public DateTime? StartDate { get; set; }

    [Column("endDate")]  // Sửa từ end_date thành endDate
    public DateTime? EndDate { get; set; }

    [MaxLength(20)]
    [Column("status")]  // Giữ nguyên
    public string Status { get; set; } = "active";

    // Navigation properties
    public OrderVoucher? OrderVoucher { get; set; }

    public ICollection<UserVoucher>? UserVouchers { get; set; }
}
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("OrderVouchers")]  // Sửa từ Order_vouchers thành OrderVouchers
public class OrderVoucher
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("orderVoucherId")]  // Sửa từ order_voucher_id thành orderVoucherId
    public string OrderVoucherId { get; set; } = null!;

    [Required]
    [Column("orderId")]  // Sửa từ order_id thành orderId
    public string OrderId { get; set; } = null!;

    [Required]
    [Column("voucherId")]  // Sửa từ voucher_id thành voucherId
    public string VoucherId { get; set; } = null!;

    [Required]
    [Column("discountAmount", TypeName = "decimal(12,2)")]  // Sửa từ discount_amount thành discountAmount
    public decimal DiscountAmount { get; set; }

    // Navigation properties
    public Order? Order { get; set; }
    public Voucher? Voucher { get; set; }
}
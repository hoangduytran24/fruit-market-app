using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("UserVouchers")]
public class UserVoucher
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("userVoucherId")]
    public string UserVoucherId { get; set; } = null!;

    [Required]
    [Column("userId")]
    public string UserId { get; set; } = string.Empty;

    [Required]
    [Column("voucherId")]
    public string VoucherId { get; set; } = string.Empty;

    [Column("savedAt")]
    public DateTime SavedAt { get; set; } = DateTime.Now;

    [Column("usedAt")]
    public DateTime? UsedAt { get; set; }

    [Column("isUsed")]
    public bool IsUsed { get; set; } = false;

    // Navigation properties
    [ForeignKey("UserId")]
    public User? User { get; set; }

    [ForeignKey("VoucherId")]
    public Voucher? Voucher { get; set; }
}
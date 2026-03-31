using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Suppliers")]
public class Supplier
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("supplierId")]
    public string SupplierId { get; set; } = null!;

    [Required]
    [MaxLength(150)]
    [Column("supplierName")]
    public string SupplierName { get; set; } = string.Empty;

    [MaxLength(15)]
    [Column("phone")]
    public string? Phone { get; set; }

    [MaxLength(100)]  // THÊM DÒNG NÀY - Giới hạn 100 ký tự cho email
    [Column("email")]  // THÊM DÒNG NÀY - Tên cột trong database
    public string? Email { get; set; }  // THÊM DÒNG NÀY

    [MaxLength(255)]
    [Column("address")]
    public string? Address { get; set; }

    [MaxLength(20)]
    [Column("status")]
    public string Status { get; set; } = "active";

    [Column("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public ICollection<Product>? Products { get; set; }
}
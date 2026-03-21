using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Suppliers")]
public class Supplier
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("supplierId")]  // Sửa từ supplier_id thành supplierId
    public string SupplierId { get; set; } = null!;

    [Required]
    [MaxLength(150)]
    [Column("supplierName")]  // Sửa từ supplier_name thành supplierName
    public string SupplierName { get; set; } = string.Empty;

    [MaxLength(15)]
    [Column("phone")]  // Giữ nguyên
    public string? Phone { get; set; }

    [MaxLength(255)]
    [Column("address")]  // Giữ nguyên
    public string? Address { get; set; }

    [MaxLength(20)]
    [Column("status")]  // Giữ nguyên
    public string Status { get; set; } = "active";

    [Column("createdAt")]  // Sửa từ created_at thành createdAt
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public ICollection<Product>? Products { get; set; }
}
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Inventory")]
public class Inventory
{
    [Key]
    [Column("inventoryId")]
    [StringLength(20)]
    public string InventoryId { get; set; } = null!;

    [Required]
    [Column("productId")]
    [StringLength(20)]
    public string ProductId { get; set; } = null!;

    [Required]
    [MaxLength(50)]
    [Column("batchCode")]
    public string BatchCode { get; set; } = string.Empty;

    [Required]
    [Column("quantity")]
    public int Quantity { get; set; }

    [Required]
    [Column("manufactureDate", TypeName = "DATE")]
    public DateTime? ManufactureDate { get; set; }

    [Required]
    [Column("expiryDate", TypeName = "DATE")]
    public DateTime ExpiryDate { get; set; }

    [Required]
    [Column("importPrice", TypeName = "decimal(12,2)")]
    public decimal? ImportPrice { get; set; }

    [Column("importDate")]
    public DateTime ImportDate { get; set; } = DateTime.Now;

    [Column("status")]
    [StringLength(20)]
    public string Status { get; set; } = "in_stock";

    [Column("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    [ForeignKey("ProductId")]
    public virtual Product? Product { get; set; }

    // Helper properties (không lưu trong database)
    [NotMapped]
    public bool IsExpired => ExpiryDate < DateTime.Today;

    [NotMapped]
    public bool IsInStock => Status == "in_stock" && Quantity > 0 && !IsExpired;

    [NotMapped]
    public int DaysToExpiry => ExpiryDate > DateTime.Today
        ? (ExpiryDate - DateTime.Today).Days
        : 0;
}
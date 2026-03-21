using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Products")]
public class Product
{
    [Key]
    [Column("productId")]
    [StringLength(20)]
    public string ProductId { get; set; } = null!;

    [Required]
    [Column("categoryId")]
    public string CategoryId { get; set; } = null!;

    [Required]
    [Column("supplierId")]
    public string SupplierId { get; set; } = null!;

    [Required]
    [MaxLength(150)]
    [Column("productName")]
    public string ProductName { get; set; } = string.Empty;

    [Required]
    [MaxLength(50)]
    [Column("unit")]
    public string Unit { get; set; } = string.Empty;

    [Required]
    [Column("price", TypeName = "decimal(12,2)")]
    public decimal Price { get; set; }

    [Column("stockQuantity")]
    public int StockQuantity { get; set; }

    [Column("description")]
    public string? Description { get; set; }

    [MaxLength(255)]
    [Column("imageUrl")]
    public string? ImageUrl { get; set; }

    [Column("isActive")]
    public bool IsActive { get; set; } = true;

    [Column("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public Category? Category { get; set; }
    public Supplier? Supplier { get; set; }
    public ICollection<CartItem>? CartItems { get; set; }
    public ICollection<OrderItem>? OrderItems { get; set; }
    public ICollection<Review>? Reviews { get; set; }
    public ICollection<Favorite>? Favorites { get; set; }
}
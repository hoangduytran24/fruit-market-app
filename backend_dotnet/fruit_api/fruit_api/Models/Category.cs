using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Categories")]
public class Category
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("categoryId")]
    public string CategoryId { get; set; } = null!;

    [Required]
    [MaxLength(100)]
    [Column("categoryName")]
    public string CategoryName { get; set; } = string.Empty;

    [MaxLength(255)]
    [Column("description")]
    public string? Description { get; set; }

    [Column("imageUrl")]
    [MaxLength(255)]
    public string? ImageUrl { get; set; }

    [Column("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public ICollection<Product>? Products { get; set; }
}
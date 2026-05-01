using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace fruit_api.Models;

[Table("Carts")]
public class Cart
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    [Column("cartId")] 
    public string CartId { get; set; } = null!;

    [Required]
    [Column("userId")]
    public string UserId { get; set; } = null!;

    [Column("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    [Column("updatedAt")]
    public DateTime UpdatedAt { get; set; } = DateTime.Now;

    // Navigation properties
    public User? User { get; set; }
    public ICollection<CartItem>? CartItems { get; set; }
}
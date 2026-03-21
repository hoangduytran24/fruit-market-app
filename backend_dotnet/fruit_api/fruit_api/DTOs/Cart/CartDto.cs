namespace fruit_api.DTOs.Cart;

public class CartItemDto
{
    public string CartItemId { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string Unit { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int Quantity { get; set; }
    public decimal Subtotal { get; set; }
}

public class CartDto
{
    public string CartId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public List<CartItemDto> Items { get; set; } = new();
    public int TotalItems { get; set; }
    public decimal TotalPrice { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class AddToCartDto
{
    public string ProductId { get; set; } = string.Empty;
    public int Quantity { get; set; }
}

public class UpdateCartItemDto
{
    public int Quantity { get; set; }
}
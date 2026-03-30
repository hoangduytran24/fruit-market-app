namespace fruit_api.DTOs.Order;

public class BuyNowDto
{
    public string ProductId { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public string DeliveryAddress { get; set; } = string.Empty;
    public string? VoucherCode { get; set; }
    public decimal ShippingFee { get; set; } = 25000;
}

public class OrderItemDto
{
    public string ProductId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public int Quantity { get; set; }
    public decimal Price { get; set; }
    public decimal Subtotal { get; set; }
}

public class OrderDto
{
    public string OrderId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal FinalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? PaymentMethod { get; set; }
    public string? PaymentStatus { get; set; }
    public string DeliveryAddress { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public List<OrderItemDto> Items { get; set; } = new();
    public string? VoucherCode { get; set; }
}

public class OrderListDto
{
    public string OrderId { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;      // THÊM DÒNG NÀY
    public string CustomerPhone { get; set; } = string.Empty;     // THÊM DÒNG NÀY
    public string DeliveryAddress { get; set; } = string.Empty;   // THÊM DÒNG NÀY
    public string? PaymentStatus { get; set; }
    public DateTime CreatedAt { get; set; }
    public decimal FinalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public int ItemCount { get; set; }
}

public class CreateOrderDto
{
    public string DeliveryAddress { get; set; } = string.Empty;
    public string PaymentMethod { get; set; } = string.Empty;
    public string? VoucherCode { get; set; }
    public decimal ShippingFee { get; set; } = 25000;
}

public class UpdateOrderStatusDto
{
    public string Status { get; set; } = string.Empty;
}
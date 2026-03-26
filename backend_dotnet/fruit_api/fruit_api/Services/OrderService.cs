using Microsoft.EntityFrameworkCore;
using fruit_api.Data;
using fruit_api.DTOs.Order;
using fruit_api.Models;
using fruit_api.Services.Interfaces;

namespace fruit_api.Services;

public class OrderService : IOrderService
{
    private readonly ApplicationDbContext _context;
    private readonly IVoucherService _voucherService;
    private static readonly Random _random = new();

    public OrderService(ApplicationDbContext context, IVoucherService voucherService)
    {
        _context = context;
        _voucherService = voucherService;
    }

    private async Task<string> GenerateOrderId()
    {
        string orderId;
        bool exists;
        int attempt = 0;
        const int maxAttempts = 10;

        do
        {
            var randomNumber = _random.Next(100000, 999999).ToString();
            orderId = "OD" + randomNumber;
            exists = await _context.Orders.AnyAsync(o => o.OrderId == orderId);
            attempt++;

            if (attempt >= maxAttempts)
                throw new Exception("Không thể tạo ID đơn hàng duy nhất");

        } while (exists);

        return orderId;
    }

    private async Task<string> GenerateOrderItemId()
    {
        string orderItemId;
        bool exists;
        int attempt = 0;
        const int maxAttempts = 10;

        do
        {
            var randomNumber = _random.Next(100000, 999999).ToString();
            orderItemId = "OI" + randomNumber;
            exists = await _context.OrderItems.AnyAsync(oi => oi.OrderItemId == orderItemId);
            attempt++;

            if (attempt >= maxAttempts)
                throw new Exception("Không thể tạo ID order item duy nhất");

        } while (exists);

        return orderItemId;
    }

    private async Task<string> GeneratePaymentId()
    {
        string paymentId;
        bool exists;
        int attempt = 0;
        const int maxAttempts = 10;

        do
        {
            var randomNumber = _random.Next(100000, 999999).ToString();
            paymentId = "PM" + randomNumber;
            exists = await _context.Payments.AnyAsync(p => p.PaymentId == paymentId);
            attempt++;

            if (attempt >= maxAttempts)
                throw new Exception("Không thể tạo ID payment duy nhất");

        } while (exists);

        return paymentId;
    }

    private async Task<string> GenerateOrderVoucherId()
    {
        string orderVoucherId;
        bool exists;
        int attempt = 0;
        const int maxAttempts = 10;

        do
        {
            var randomNumber = _random.Next(100000, 999999).ToString();
            orderVoucherId = "OV" + randomNumber;
            exists = await _context.OrderVouchers.AnyAsync(ov => ov.OrderVoucherId == orderVoucherId);
            attempt++;

            if (attempt >= maxAttempts)
                throw new Exception("Không thể tạo ID order voucher duy nhất");

        } while (exists);

        return orderVoucherId;
    }

    public async Task<IEnumerable<OrderListDto>> GetUserOrdersAsync(string userId)
    {
        return await _context.Orders
            .Where(o => o.UserId == userId)
            .Include(o => o.OrderItems)
            .OrderByDescending(o => o.CreatedAt)
            .Select(o => new OrderListDto
            {
                OrderId = o.OrderId,
                CreatedAt = o.CreatedAt,
                FinalAmount = o.FinalAmount,
                Status = o.Status,
                ItemCount = o.OrderItems != null ? o.OrderItems.Count : 0
            })
            .ToListAsync();
    }

    public async Task<IEnumerable<OrderListDto>> GetAllOrdersAsync(string? status = null)
    {
        var query = _context.Orders
            .Include(o => o.OrderItems)
            .Include(o => o.User)
            .OrderByDescending(o => o.CreatedAt)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status))
        {
            query = query.Where(o => o.Status == status);
        }

        return await query.Select(o => new OrderListDto
        {
            OrderId = o.OrderId,
            CreatedAt = o.CreatedAt,
            FinalAmount = o.FinalAmount,
            Status = o.Status,
            ItemCount = o.OrderItems != null ? o.OrderItems.Count : 0
        }).ToListAsync();
    }

    public async Task<OrderDto?> GetOrderByIdAsync(string id)
    {
        var order = await _context.Orders
            .Include(o => o.User)
            .Include(o => o.OrderItems!)
                .ThenInclude(oi => oi.Product)
            .Include(o => o.OrderVoucher)
                .ThenInclude(ov => ov!.Voucher)
            .Include(o => o.Payment)
            .FirstOrDefaultAsync(o => o.OrderId == id);

        if (order == null)
            return null;

        return new OrderDto
        {
            OrderId = order.OrderId,
            UserId = order.UserId,
            CustomerName = order.User?.FullName ?? string.Empty,
            CustomerPhone = order.User?.Phone,
            TotalAmount = order.TotalAmount,
            DiscountAmount = order.DiscountAmount,
            FinalAmount = order.FinalAmount,
            Status = order.Status,
            PaymentMethod = order.PaymentMethod,
            PaymentStatus = order.Payment?.PaymentStatus ?? "unpaid",
            DeliveryAddress = order.DeliveryAddress,
            CreatedAt = order.CreatedAt,
            VoucherCode = order.OrderVoucher?.Voucher?.VoucherCode,
            Items = order.OrderItems?.Select(oi => new OrderItemDto
            {
                ProductId = oi.ProductId,
                ProductName = oi.Product?.ProductName ?? string.Empty,
                ImageUrl = oi.Product?.ImageUrl,
                Quantity = oi.Quantity,
                Price = oi.PriceAtTime,
                Subtotal = oi.Subtotal
            }).ToList() ?? new List<OrderItemDto>()
        };
    }

    public async Task<OrderDto> CreateOrderAsync(string userId, CreateOrderDto createOrderDto)
    {
        // Get user's cart
        var cart = await _context.Carts
            .Include(c => c.CartItems!)
                .ThenInclude(ci => ci.Product)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart == null || cart.CartItems == null || !cart.CartItems.Any())
            throw new Exception("Cart is empty");

        // Check stock and calculate subtotal (tổng tiền hàng chưa bao gồm phí ship)
        decimal subtotal = 0;
        foreach (var item in cart.CartItems)
        {
            if (item.Product == null)
                throw new Exception($"Product not found");

            if (item.Product.StockQuantity < item.Quantity)
                throw new Exception($"Not enough stock for product: {item.Product.ProductName}");

            subtotal += item.Quantity * item.PriceAtTime;
        }

        // Áp dụng voucher trên subtotal
        decimal discountAmount = 0;
        OrderVoucher? orderVoucher = null;

        if (!string.IsNullOrEmpty(createOrderDto.VoucherCode))
        {
            var voucherResult = await _voucherService.ApplyVoucherAsync(new DTOs.Voucher.ApplyVoucherDto
            {
                VoucherCode = createOrderDto.VoucherCode,
                OrderTotal = subtotal
            });

            if (voucherResult.IsValid && voucherResult.Voucher != null)
            {
                discountAmount = voucherResult.DiscountAmount;
                orderVoucher = new OrderVoucher
                {
                    OrderVoucherId = await GenerateOrderVoucherId(),
                    VoucherId = voucherResult.Voucher.VoucherId,
                    DiscountAmount = discountAmount
                };
            }
        }

        // SỬA QUAN TRỌNG: totalAmount = subtotal + shippingFee (chưa trừ giảm giá)
        // Database sẽ tự tính finalAmount = totalAmount - discountAmount
        decimal totalAmount = subtotal + createOrderDto.ShippingFee;

        // Create order
        var order = new Order
        {
            OrderId = await GenerateOrderId(),
            UserId = userId,
            TotalAmount = totalAmount,           // = subtotal + shippingFee
            DiscountAmount = discountAmount,      // số tiền giảm
            Status = "pending",
            PaymentMethod = createOrderDto.PaymentMethod,
            DeliveryAddress = createOrderDto.DeliveryAddress,
            CreatedAt = DateTime.UtcNow
        };

        _context.Orders.Add(order);
        await _context.SaveChangesAsync();

        // Create order items
        foreach (var item in cart.CartItems)
        {
            var orderItem = new OrderItem
            {
                OrderItemId = await GenerateOrderItemId(),
                OrderId = order.OrderId,
                ProductId = item.ProductId,
                Quantity = item.Quantity,
                PriceAtTime = item.PriceAtTime
            };
            _context.OrderItems.Add(orderItem);

            // Update stock
            var product = await _context.Products.FindAsync(item.ProductId);
            if (product != null)
            {
                product.StockQuantity -= item.Quantity;
            }
        }

        // Add order voucher if exists
        if (orderVoucher != null)
        {
            orderVoucher.OrderId = order.OrderId;
            _context.OrderVouchers.Add(orderVoucher);
        }

        // Clear cart
        _context.CartItems.RemoveRange(cart.CartItems);
        cart.UpdatedAt = DateTime.UtcNow;

        // Create payment record (số tiền thực tế cần thanh toán)
        var payment = new Payment
        {
            PaymentId = await GeneratePaymentId(),
            OrderId = order.OrderId,
            Amount = subtotal + createOrderDto.ShippingFee - discountAmount,
            PaymentMethod = createOrderDto.PaymentMethod,
            PaymentStatus = "unpaid"
        };
        _context.Payments.Add(payment);

        await _context.SaveChangesAsync();

        return await GetOrderByIdAsync(order.OrderId) ?? throw new Exception("Failed to create order");
    }

    public async Task<OrderDto> BuyNowAsync(string userId, BuyNowDto buyNowDto)
    {
        // Validate input
        if (buyNowDto.Quantity <= 0)
            throw new Exception("Quantity must be greater than 0");

        if (string.IsNullOrEmpty(buyNowDto.DeliveryAddress))
            throw new Exception("Delivery address is required");

        if (string.IsNullOrEmpty(buyNowDto.PaymentMethod))
            throw new Exception("Payment method is required");

        // Get product
        var product = await _context.Products.FindAsync(buyNowDto.ProductId);

        if (product == null)
            throw new Exception("Product not found");

        // Check stock
        if (product.StockQuantity < buyNowDto.Quantity)
            throw new Exception($"Not enough stock for product: {product.ProductName}. Available: {product.StockQuantity}");

        // Calculate subtotal (tổng tiền hàng chưa bao gồm phí ship)
        decimal subtotal = product.Price * buyNowDto.Quantity;

        // Áp dụng voucher trên subtotal
        decimal discountAmount = 0;
        OrderVoucher? orderVoucher = null;

        if (!string.IsNullOrEmpty(buyNowDto.VoucherCode) && buyNowDto.VoucherCode != "null")
        {
            var voucherResult = await _voucherService.ApplyVoucherAsync(new DTOs.Voucher.ApplyVoucherDto
            {
                VoucherCode = buyNowDto.VoucherCode,
                OrderTotal = subtotal
            });

            if (voucherResult.IsValid && voucherResult.Voucher != null)
            {
                discountAmount = voucherResult.DiscountAmount;
                orderVoucher = new OrderVoucher
                {
                    OrderVoucherId = await GenerateOrderVoucherId(),
                    VoucherId = voucherResult.Voucher.VoucherId,
                    DiscountAmount = discountAmount
                };
            }
        }

        // SỬA QUAN TRỌNG: totalAmount = subtotal + shippingFee (chưa trừ giảm giá)
        decimal totalAmount = subtotal + buyNowDto.ShippingFee;

        // Create order
        var order = new Order
        {
            OrderId = await GenerateOrderId(),
            UserId = userId,
            TotalAmount = totalAmount,           // = subtotal + shippingFee
            DiscountAmount = discountAmount,      // số tiền giảm
            Status = "pending",
            PaymentMethod = buyNowDto.PaymentMethod,
            DeliveryAddress = buyNowDto.DeliveryAddress,
            CreatedAt = DateTime.UtcNow
        };

        _context.Orders.Add(order);
        await _context.SaveChangesAsync();

        // Create order item
        var orderItem = new OrderItem
        {
            OrderItemId = await GenerateOrderItemId(),
            OrderId = order.OrderId,
            ProductId = product.ProductId,
            Quantity = buyNowDto.Quantity,
            PriceAtTime = product.Price
        };
        _context.OrderItems.Add(orderItem);

        // Update stock
        product.StockQuantity -= buyNowDto.Quantity;

        // Add order voucher if exists
        if (orderVoucher != null)
        {
            orderVoucher.OrderId = order.OrderId;
            _context.OrderVouchers.Add(orderVoucher);
        }

        // Create payment record (số tiền thực tế cần thanh toán)
        var payment = new Payment
        {
            PaymentId = await GeneratePaymentId(),
            OrderId = order.OrderId,
            Amount = subtotal + buyNowDto.ShippingFee - discountAmount,
            PaymentMethod = buyNowDto.PaymentMethod,
            PaymentStatus = "unpaid"
        };
        _context.Payments.Add(payment);

        await _context.SaveChangesAsync();

        return await GetOrderByIdAsync(order.OrderId) ?? throw new Exception("Failed to create order");
    }

    public async Task<OrderDto> UpdateOrderStatusAsync(string id, UpdateOrderStatusDto updateDto)
    {
        var order = await _context.Orders.FindAsync(id);
        if (order == null)
            throw new Exception("Order not found");

        order.Status = updateDto.Status;

        // Cập nhật payment status dựa trên order status
        var payment = await _context.Payments.FirstOrDefaultAsync(p => p.OrderId == id);

        if (order.Status == "completed")
        {
            if (payment != null && payment.PaymentStatus != "paid")
            {
                payment.PaymentStatus = "paid";
                payment.PaidAt = DateTime.UtcNow;
            }
        }
        else if (order.Status == "cancelled")
        {
            if (payment != null && payment.PaymentStatus != "cancelled")
            {
                payment.PaymentStatus = "cancelled";
            }
        }

        await _context.SaveChangesAsync();

        return await GetOrderByIdAsync(id) ?? throw new Exception("Order not found");
    }

    public async Task<bool> CancelOrderAsync(string id)
    {
        var order = await _context.Orders
            .Include(o => o.OrderItems)
            .FirstOrDefaultAsync(o => o.OrderId == id);

        if (order == null)
            throw new Exception("Order not found");

        if (order.Status != "pending")
            throw new Exception("Only pending orders can be cancelled");

        order.Status = "cancelled";

        // Update payment status
        var payment = await _context.Payments.FirstOrDefaultAsync(p => p.OrderId == id);
        if (payment != null)
        {
            payment.PaymentStatus = "cancelled";
        }

        // Restore stock (trigger sẽ tự động xử lý)
        await _context.SaveChangesAsync();

        return true;
    }
}
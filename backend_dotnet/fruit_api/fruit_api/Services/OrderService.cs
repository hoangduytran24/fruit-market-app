using Microsoft.EntityFrameworkCore;
using fruit_api.Data;
using fruit_api.DTOs.Order;
using fruit_api.Models;
using fruit_api.Services.Interfaces;
using fruit_api.DTOs.RealTime;

namespace fruit_api.Services;

public class OrderService : IOrderService
{
    private readonly ApplicationDbContext _context;
    private readonly IVoucherService _voucherService;
    private readonly IRealTimeService _realTimeService;
    private readonly ILogger<OrderService> _logger;
    private static readonly Random _random = new();

    public OrderService(
        ApplicationDbContext context,
        IVoucherService voucherService,
        IRealTimeService realTimeService,
        ILogger<OrderService> logger)
    {
        _context = context;
        _voucherService = voucherService;
        _realTimeService = realTimeService;
        _logger = logger;
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
            .Include(o => o.User)
            .Include(o => o.OrderItems)
            .OrderByDescending(o => o.CreatedAt)
            .Select(o => new OrderListDto
            {
                OrderId = o.OrderId,
                CustomerName = o.User != null ? o.User.FullName : string.Empty,
                CustomerPhone = o.User != null ? o.User.Phone : string.Empty,
                DeliveryAddress = o.DeliveryAddress,
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
            .Include(o => o.User)
            .Include(o => o.OrderItems)
            .Include(o => o.Payment)
            .OrderByDescending(o => o.CreatedAt)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status))
        {
            query = query.Where(o => o.Status == status);
        }

        return await query.Select(o => new OrderListDto
        {
            OrderId = o.OrderId,
            CustomerName = o.User != null ? o.User.FullName : string.Empty,
            CustomerPhone = o.User != null ? o.User.Phone : string.Empty,
            DeliveryAddress = o.DeliveryAddress,
            CreatedAt = o.CreatedAt,
            FinalAmount = o.FinalAmount,
            Status = o.Status,
            ItemCount = o.OrderItems != null ? o.OrderItems.Count : 0,
            PaymentStatus = o.Payment != null ? o.Payment.PaymentStatus : "unpaid"
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
        var cart = await _context.Carts
            .Include(c => c.CartItems!)
                .ThenInclude(ci => ci.Product)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart == null || cart.CartItems == null || !cart.CartItems.Any())
            throw new Exception("Cart is empty");

        decimal subtotal = 0;
        foreach (var item in cart.CartItems)
        {
            if (item.Product == null)
                throw new Exception($"Product not found");

            if (item.Product.StockQuantity < item.Quantity)
                throw new Exception($"Not enough stock for product: {item.Product.ProductName}");

            subtotal += item.Quantity * item.PriceAtTime;
        }

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

                var voucher = await _context.Vouchers.FindAsync(voucherResult.Voucher.VoucherId);
                if (voucher != null)
                {
                    voucher.UsedQuantity += 1;
                }
            }
        }

        decimal totalAmount = subtotal + createOrderDto.ShippingFee;
        // KHÔNG gán FinalAmount - nó sẽ tự tính trong database

        var order = new Order
        {
            OrderId = await GenerateOrderId(),
            UserId = userId,
            TotalAmount = totalAmount,
            DiscountAmount = discountAmount,
            // FinalAmount KHÔNG gán - computed property
            Status = "pending",
            PaymentMethod = createOrderDto.PaymentMethod,
            DeliveryAddress = createOrderDto.DeliveryAddress,
            CreatedAt = DateTime.UtcNow
        };

        _context.Orders.Add(order);
        await _context.SaveChangesAsync();

        var customerName = string.Empty;
        var user = await _context.Users.FindAsync(userId);
        if (user != null)
        {
            customerName = user.FullName;
        }

        foreach (var item in cart.CartItems)
        {
            var orderItem = new OrderItem
            {
                OrderItemId = await GenerateOrderItemId(),
                OrderId = order.OrderId,
                ProductId = item.ProductId,
                Quantity = item.Quantity,
                PriceAtTime = item.PriceAtTime
                // Subtotal KHÔNG gán - computed property
            };
            _context.OrderItems.Add(orderItem);

            var product = await _context.Products.FindAsync(item.ProductId);
            if (product != null)
            {
                product.StockQuantity -= item.Quantity;
            }
        }

        if (orderVoucher != null)
        {
            orderVoucher.OrderId = order.OrderId;
            _context.OrderVouchers.Add(orderVoucher);
        }

        _context.CartItems.RemoveRange(cart.CartItems);
        cart.UpdatedAt = DateTime.UtcNow;

        var payment = new Payment
        {
            PaymentId = await GeneratePaymentId(),
            OrderId = order.OrderId,
            Amount = totalAmount - discountAmount,
            PaymentMethod = createOrderDto.PaymentMethod,
            PaymentStatus = "unpaid"
        };
        _context.Payments.Add(payment);

        await _context.SaveChangesAsync();

        // ========== GỬI REAL-TIME NOTIFICATION ==========
        try
        {
            // Gửi thông báo đến admin
            await _realTimeService.NotifyNewOrderToAdminsAsync(new NewOrderNotificationDto
            {
                OrderId = order.OrderId,
                OrderCode = order.OrderId,
                CustomerName = customerName,
                TotalAmount = order.FinalAmount,
                CreatedAt = order.CreatedAt
            });

            // Gửi thông báo đến user
            await _realTimeService.NotifyUserAsync(
                userId,
                "OrderCreated",
                $"Đơn hàng {order.OrderId} đã được tạo thành công",
                new { OrderId = order.OrderId, OrderCode = order.OrderId, Status = order.Status }
            );

            _logger.LogInformation($"Real-time notifications sent for order {order.OrderId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to send real-time notifications for order {order.OrderId}");
        }
        // =============================================

        return await GetOrderByIdAsync(order.OrderId) ?? throw new Exception("Failed to create order");
    }

    public async Task<OrderDto> BuyNowAsync(string userId, BuyNowDto buyNowDto)
    {
        if (buyNowDto.Quantity <= 0)
            throw new Exception("Quantity must be greater than 0");

        if (string.IsNullOrEmpty(buyNowDto.DeliveryAddress))
            throw new Exception("Delivery address is required");

        if (string.IsNullOrEmpty(buyNowDto.PaymentMethod))
            throw new Exception("Payment method is required");

        var product = await _context.Products.FindAsync(buyNowDto.ProductId);

        if (product == null)
            throw new Exception("Product not found");

        if (product.StockQuantity < buyNowDto.Quantity)
            throw new Exception($"Not enough stock for product: {product.ProductName}. Available: {product.StockQuantity}");

        decimal subtotal = product.Price * buyNowDto.Quantity;

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

                var voucher = await _context.Vouchers.FindAsync(voucherResult.Voucher.VoucherId);
                if (voucher != null)
                {
                    voucher.UsedQuantity += 1;
                }
            }
        }

        decimal totalAmount = subtotal + buyNowDto.ShippingFee;
        // KHÔNG gán FinalAmount - computed property

        var order = new Order
        {
            OrderId = await GenerateOrderId(),
            UserId = userId,
            TotalAmount = totalAmount,
            DiscountAmount = discountAmount,
            // FinalAmount KHÔNG gán - computed property
            Status = "pending",
            PaymentMethod = buyNowDto.PaymentMethod,
            DeliveryAddress = buyNowDto.DeliveryAddress,
            CreatedAt = DateTime.UtcNow
        };

        _context.Orders.Add(order);
        await _context.SaveChangesAsync();

        var customerName = string.Empty;
        var user = await _context.Users.FindAsync(userId);
        if (user != null)
        {
            customerName = user.FullName;
        }

        var orderItem = new OrderItem
        {
            OrderItemId = await GenerateOrderItemId(),
            OrderId = order.OrderId,
            ProductId = product.ProductId,
            Quantity = buyNowDto.Quantity,
            PriceAtTime = product.Price
            // Subtotal KHÔNG gán - computed property
        };
        _context.OrderItems.Add(orderItem);

        product.StockQuantity -= buyNowDto.Quantity;

        if (orderVoucher != null)
        {
            orderVoucher.OrderId = order.OrderId;
            _context.OrderVouchers.Add(orderVoucher);
        }

        var payment = new Payment
        {
            PaymentId = await GeneratePaymentId(),
            OrderId = order.OrderId,
            Amount = totalAmount - discountAmount,
            PaymentMethod = buyNowDto.PaymentMethod,
            PaymentStatus = "unpaid"
        };
        _context.Payments.Add(payment);

        await _context.SaveChangesAsync();

        // ========== GỬI REAL-TIME NOTIFICATION ==========
        try
        {
            await _realTimeService.NotifyNewOrderToAdminsAsync(new NewOrderNotificationDto
            {
                OrderId = order.OrderId,
                OrderCode = order.OrderId,
                CustomerName = customerName,
                TotalAmount = order.FinalAmount,
                CreatedAt = order.CreatedAt
            });

            await _realTimeService.NotifyUserAsync(
                userId,
                "OrderCreated",
                $"Đơn hàng {order.OrderId} đã được tạo thành công",
                new { OrderId = order.OrderId, OrderCode = order.OrderId, Status = order.Status }
            );

            _logger.LogInformation($"Real-time notifications sent for order {order.OrderId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to send real-time notifications for order {order.OrderId}");
        }
        // =============================================

        return await GetOrderByIdAsync(order.OrderId) ?? throw new Exception("Failed to create order");
    }

    public async Task<OrderDto> UpdateOrderStatusAsync(string id, UpdateOrderStatusDto updateDto)
    {
        var order = await _context.Orders
            .Include(o => o.User)
            .FirstOrDefaultAsync(o => o.OrderId == id);

        if (order == null)
            throw new Exception("Order not found");

        var oldStatus = order.Status;
        order.Status = updateDto.Status;

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

        // ========== GỬI REAL-TIME NOTIFICATION ==========
        try
        {
            await _realTimeService.NotifyOrderStatusChangedAsync(
                order.OrderId,
                order.UserId,
                oldStatus,
                updateDto.Status,
                order.OrderId
            );

            _logger.LogInformation($"Real-time status update sent for order {id}: {oldStatus} -> {updateDto.Status}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to send real-time status update for order {id}");
        }
        // =============================================

        return await GetOrderByIdAsync(id) ?? throw new Exception("Order not found");
    }

    public async Task<bool> CancelOrderAsync(string id)
    {
        var order = await _context.Orders
            .Include(o => o.OrderItems)
            .Include(o => o.User)
            .FirstOrDefaultAsync(o => o.OrderId == id);

        if (order == null)
            throw new Exception("Order not found");

        if (order.Status != "pending" && order.Status != "processing")
            throw new Exception("Only pending or processing orders can be cancelled");

        var oldStatus = order.Status;
        order.Status = "cancelled";

        var payment = await _context.Payments.FirstOrDefaultAsync(p => p.OrderId == id);
        if (payment != null)
        {
            payment.PaymentStatus = "cancelled";
        }

        await _context.SaveChangesAsync();

        // ========== GỬI REAL-TIME NOTIFICATION ==========
        try
        {
            await _realTimeService.NotifyOrderStatusChangedAsync(
                order.OrderId,
                order.UserId,
                oldStatus,
                "cancelled",
                order.OrderId
            );

            _logger.LogInformation($"Real-time cancellation notification sent for order {id}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to send real-time cancellation for order {id}");
        }
        // =============================================

        return true;
    }
}
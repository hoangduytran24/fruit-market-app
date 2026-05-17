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

    // Khai báo hằng số phí ship cố định
    private const decimal SHIPPING_FEE = 25000m;

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

    // ==================== HELPER METHODS FOR VOUCHER USAGE ====================

    private async Task<bool> HasUserUsedVoucherAsync(string userId, string voucherCode)
    {
        var voucher = await _context.Vouchers
            .FirstOrDefaultAsync(v => v.VoucherCode == voucherCode.ToUpper().Trim());

        if (voucher == null)
            return false;

        var hasUsed = await _context.UserVouchers
            .AnyAsync(uv => uv.UserId == userId
                && uv.VoucherId == voucher.VoucherId
                && uv.IsUsed == true);

        return hasUsed;
    }

    private async Task MarkVoucherAsUsedAsync(string userId, string voucherCode)
    {
        var voucher = await _context.Vouchers
            .FirstOrDefaultAsync(v => v.VoucherCode == voucherCode.ToUpper().Trim());

        if (voucher == null)
            return;

        var userVoucher = await _context.UserVouchers
            .FirstOrDefaultAsync(uv => uv.UserId == userId
                && uv.VoucherId == voucher.VoucherId
                && uv.IsUsed == false);

        if (userVoucher != null)
        {
            userVoucher.IsUsed = true;
            userVoucher.UsedAt = DateTime.Now;
            await _context.SaveChangesAsync();
            _logger.LogInformation($"Marked voucher {voucherCode} as used for user {userId}");
        }
    }

    private async Task MarkVoucherAsUnusedAsync(string userId, string voucherCode)
    {
        var voucher = await _context.Vouchers
            .FirstOrDefaultAsync(v => v.VoucherCode == voucherCode.ToUpper().Trim());

        if (voucher == null)
            return;

        var userVoucher = await _context.UserVouchers
            .FirstOrDefaultAsync(uv => uv.UserId == userId
                && uv.VoucherId == voucher.VoucherId
                && uv.IsUsed == true);

        if (userVoucher != null)
        {
            userVoucher.IsUsed = false;
            userVoucher.UsedAt = null;
            await _context.SaveChangesAsync();
            _logger.LogInformation($"Marked voucher {voucherCode} as unused for user {userId}");
        }
    }

    // ==================== PUBLIC METHODS ====================

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
                ReceiverName = o.ReceiverName,
                ReceiverPhone = o.ReceiverPhone,
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
            ReceiverName = o.ReceiverName,
            ReceiverPhone = o.ReceiverPhone,
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
            ReceiverName = order.ReceiverName,
            ReceiverPhone = order.ReceiverPhone,
            CreatedAt = order.CreatedAt,
            CompletedAt = order.CompletedAt,
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

    // ========== TẠO ĐƠN HÀNG TỪ DANH SÁCH SẢN PHẨM ĐƯỢC CHỌN ==========
    public async Task<OrderDto> CreateOrderFromSelectedItemsAsync(string userId, CreateOrderFromSelectedItemsDto createOrderDto)
    {
        if (createOrderDto.Items == null || !createOrderDto.Items.Any())
            throw new Exception("Không có sản phẩm nào được chọn");

        if (string.IsNullOrEmpty(createOrderDto.DeliveryAddress))
            throw new Exception("Địa chỉ giao hàng không được để trống");

        if (string.IsNullOrEmpty(createOrderDto.ReceiverName))
            throw new Exception("Tên người nhận không được để trống");

        if (string.IsNullOrEmpty(createOrderDto.ReceiverPhone))
            throw new Exception("Số điện thoại người nhận không được để trống");

        decimal subtotal = 0;
        var orderItems = new List<(string ProductId, int Quantity, decimal PriceAtTime)>();

        foreach (var item in createOrderDto.Items)
        {
            var product = await _context.Products.FindAsync(item.ProductId);

            if (product == null)
                throw new Exception($"Sản phẩm với ID {item.ProductId} không tồn tại");

            if (!product.IsActive)
                throw new Exception($"Sản phẩm '{product.ProductName}' đã ngừng kinh doanh, không thể thanh toán");

            if (product.StockQuantity < item.Quantity)
                throw new Exception($"Sản phẩm {product.ProductName} không đủ số lượng. Còn lại: {product.StockQuantity}");

            subtotal += product.Price * item.Quantity;
            orderItems.Add((item.ProductId, item.Quantity, product.Price));
        }

        // Tính giảm giá từ voucher
        decimal discountAmount = 0;
        OrderVoucher? orderVoucher = null;
        string? usedVoucherCode = null;

        if (!string.IsNullOrEmpty(createOrderDto.VoucherCode) && createOrderDto.VoucherCode != "null")
        {
            // ✅ KIỂM TRA USER ĐÃ DÙNG VOUCHER NÀY CHƯA
            var hasUsed = await HasUserUsedVoucherAsync(userId, createOrderDto.VoucherCode);
            if (hasUsed)
            {
                throw new Exception("Bạn đã sử dụng voucher này rồi! Mỗi voucher chỉ được dùng 1 lần.");
            }

            var voucherResult = await _voucherService.ApplyVoucherAsync(new DTOs.Voucher.ApplyVoucherDto
            {
                VoucherCode = createOrderDto.VoucherCode,
                OrderTotal = subtotal
            });

            if (voucherResult.IsValid && voucherResult.Voucher != null)
            {
                discountAmount = voucherResult.DiscountAmount;
                usedVoucherCode = createOrderDto.VoucherCode;

                var voucher = await _context.Vouchers.FindAsync(voucherResult.Voucher.VoucherId);
                if (voucher != null)
                {
                    orderVoucher = new OrderVoucher
                    {
                        OrderVoucherId = await GenerateOrderVoucherId(),
                        VoucherId = voucher.VoucherId,
                        DiscountAmount = discountAmount
                    };

                    voucher.UsedQuantity += 1;
                }
            }
        }

        decimal totalAmount = subtotal + SHIPPING_FEE;

        var order = new Order
        {
            OrderId = await GenerateOrderId(),
            UserId = userId,
            TotalAmount = totalAmount,
            DiscountAmount = discountAmount,
            Status = "pending",
            PaymentMethod = createOrderDto.PaymentMethod,
            DeliveryAddress = createOrderDto.DeliveryAddress,
            ReceiverName = createOrderDto.ReceiverName,
            ReceiverPhone = createOrderDto.ReceiverPhone,
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

        // Thêm các order items và cập nhật stock
        foreach (var item in orderItems)
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

        // ✅ ĐÁNH DẤU VOUCHER ĐÃ ĐƯỢC SỬ DỤNG
        if (!string.IsNullOrEmpty(usedVoucherCode))
        {
            await MarkVoucherAsUsedAsync(userId, usedVoucherCode);
        }

        // Gửi real-time notifications
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

        return await GetOrderByIdAsync(order.OrderId) ?? throw new Exception("Failed to create order");
    }

    // ========== TẠO ĐƠN HÀNG TỪ GIỎ HÀNG (TOÀN BỘ) ==========
    public async Task<OrderDto> CreateOrderAsync(string userId, CreateOrderDto createOrderDto)
    {
        var cart = await _context.Carts
            .Include(c => c.CartItems!)
                .ThenInclude(ci => ci.Product)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart == null || cart.CartItems == null || !cart.CartItems.Any())
            throw new Exception("Giỏ hàng trống");

        decimal subtotal = 0;
        foreach (var item in cart.CartItems)
        {
            if (item.Product == null)
                throw new Exception($"Sản phẩm không tồn tại");

            if (!item.Product.IsActive)
                throw new Exception($"Sản phẩm '{item.Product.ProductName}' đã ngừng kinh doanh, không thể thanh toán. Vui lòng xóa sản phẩm này khỏi giỏ hàng.");

            if (item.Product.StockQuantity < item.Quantity)
                throw new Exception($"Sản phẩm {item.Product.ProductName} không đủ số lượng. Còn lại: {item.Product.StockQuantity}");

            subtotal += item.Quantity * item.PriceAtTime;
        }

        decimal discountAmount = 0;
        OrderVoucher? orderVoucher = null;
        string? usedVoucherCode = null;

        if (!string.IsNullOrEmpty(createOrderDto.VoucherCode) && createOrderDto.VoucherCode != "null")
        {
            // ✅ KIỂM TRA USER ĐÃ DÙNG VOUCHER NÀY CHƯA
            var hasUsed = await HasUserUsedVoucherAsync(userId, createOrderDto.VoucherCode);
            if (hasUsed)
            {
                throw new Exception("Bạn đã sử dụng voucher này rồi! Mỗi voucher chỉ được dùng 1 lần.");
            }

            var voucherResult = await _voucherService.ApplyVoucherAsync(new DTOs.Voucher.ApplyVoucherDto
            {
                VoucherCode = createOrderDto.VoucherCode,
                OrderTotal = subtotal
            });

            if (voucherResult.IsValid && voucherResult.Voucher != null)
            {
                discountAmount = voucherResult.DiscountAmount;
                usedVoucherCode = createOrderDto.VoucherCode;
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

        decimal totalAmount = subtotal + SHIPPING_FEE;

        var order = new Order
        {
            OrderId = await GenerateOrderId(),
            UserId = userId,
            TotalAmount = totalAmount,
            DiscountAmount = discountAmount,
            Status = "pending",
            PaymentMethod = createOrderDto.PaymentMethod,
            DeliveryAddress = createOrderDto.DeliveryAddress,
            ReceiverName = createOrderDto.ReceiverName,
            ReceiverPhone = createOrderDto.ReceiverPhone,
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

        // ✅ ĐÁNH DẤU VOUCHER ĐÃ ĐƯỢC SỬ DỤNG
        if (!string.IsNullOrEmpty(usedVoucherCode))
        {
            await MarkVoucherAsUsedAsync(userId, usedVoucherCode);
        }

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

        return await GetOrderByIdAsync(order.OrderId) ?? throw new Exception("Failed to create order");
    }

    // ========== MUA NGAY ==========
    public async Task<OrderDto> BuyNowAsync(string userId, BuyNowDto buyNowDto)
    {
        if (buyNowDto.Quantity <= 0)
            throw new Exception("Số lượng phải lớn hơn 0");

        if (string.IsNullOrEmpty(buyNowDto.DeliveryAddress))
            throw new Exception("Địa chỉ giao hàng không được để trống");

        if (string.IsNullOrEmpty(buyNowDto.PaymentMethod))
            throw new Exception("Phương thức thanh toán không được để trống");

        var product = await _context.Products.FindAsync(buyNowDto.ProductId);

        if (product == null)
            throw new Exception("Sản phẩm không tồn tại");

        if (!product.IsActive)
            throw new Exception($"Sản phẩm '{product.ProductName}' đã ngừng kinh doanh, không thể mua");

        if (product.StockQuantity < buyNowDto.Quantity)
            throw new Exception($"Sản phẩm {product.ProductName} không đủ số lượng. Còn lại: {product.StockQuantity}");

        decimal subtotal = product.Price * buyNowDto.Quantity;

        decimal discountAmount = 0;
        OrderVoucher? orderVoucher = null;
        string? usedVoucherCode = null;

        if (!string.IsNullOrEmpty(buyNowDto.VoucherCode) && buyNowDto.VoucherCode != "null")
        {
            // ✅ KIỂM TRA USER ĐÃ DÙNG VOUCHER NÀY CHƯA
            var hasUsed = await HasUserUsedVoucherAsync(userId, buyNowDto.VoucherCode);
            if (hasUsed)
            {
                throw new Exception("Bạn đã sử dụng voucher này rồi! Mỗi voucher chỉ được dùng 1 lần.");
            }

            var voucherResult = await _voucherService.ApplyVoucherAsync(new DTOs.Voucher.ApplyVoucherDto
            {
                VoucherCode = buyNowDto.VoucherCode,
                OrderTotal = subtotal
            });

            if (voucherResult.IsValid && voucherResult.Voucher != null)
            {
                discountAmount = voucherResult.DiscountAmount;
                usedVoucherCode = buyNowDto.VoucherCode;
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

        decimal totalAmount = subtotal + SHIPPING_FEE;

        var order = new Order
        {
            OrderId = await GenerateOrderId(),
            UserId = userId,
            TotalAmount = totalAmount,
            DiscountAmount = discountAmount,
            Status = "pending",
            PaymentMethod = buyNowDto.PaymentMethod,
            DeliveryAddress = buyNowDto.DeliveryAddress,
            ReceiverName = buyNowDto.ReceiverName,
            ReceiverPhone = buyNowDto.ReceiverPhone,
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

        // ✅ ĐÁNH DẤU VOUCHER ĐÃ ĐƯỢC SỬ DỤNG
        if (!string.IsNullOrEmpty(usedVoucherCode))
        {
            await MarkVoucherAsUsedAsync(userId, usedVoucherCode);
        }

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

        return await GetOrderByIdAsync(order.OrderId) ?? throw new Exception("Failed to create order");
    }

    // ========== CẬP NHẬT TRẠNG THÁI ĐƠN HÀNG ==========
    public async Task<OrderDto> UpdateOrderStatusAsync(string id, UpdateOrderStatusDto updateDto)
    {
        var order = await _context.Orders
            .Include(o => o.User)
            .Include(o => o.OrderVoucher)
                .ThenInclude(ov => ov!.Voucher)
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

            // ✅ NẾU HỦY ĐƠN, HOÀN TRẢ VOUCHER CHO USER
            if (order.OrderVoucher?.Voucher != null)
            {
                await MarkVoucherAsUnusedAsync(order.UserId, order.OrderVoucher.Voucher.VoucherCode);
            }
        }

        await _context.SaveChangesAsync();

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

        return await GetOrderByIdAsync(id) ?? throw new Exception("Order not found");
    }

    // ========== HỦY ĐƠN HÀNG ==========
    public async Task<bool> CancelOrderAsync(string id)
    {
        var order = await _context.Orders
            .Include(o => o.OrderItems)
            .Include(o => o.User)
            .Include(o => o.OrderVoucher)
                .ThenInclude(ov => ov!.Voucher)
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

        // ✅ NẾU ĐƠN HÀNG CÓ DÙNG VOUCHER, HOÀN TRẢ CHO USER
        if (order.OrderVoucher?.Voucher != null)
        {
            await MarkVoucherAsUnusedAsync(order.UserId, order.OrderVoucher.Voucher.VoucherCode);
        }

        await _context.SaveChangesAsync();

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

        return true;
    }
}
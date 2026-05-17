using Microsoft.EntityFrameworkCore;
using fruit_api.Data;
using fruit_api.DTOs.Payment;
using fruit_api.Models;
using fruit_api.Services.Interfaces;

namespace fruit_api.Services;

public class PaymentService : IPaymentService
{
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _config;
    private readonly ILogger<PaymentService> _logger;

    public PaymentService(
        ApplicationDbContext context,
        IConfiguration config,
        ILogger<PaymentService> logger)
    {
        _context = context;
        _config = config;
        _logger = logger;
    }

    public async Task<PaymentQRResponseDto> GeneratePaymentQRAsync(string orderId)
    {
        // 1. Kiểm tra đơn hàng
        var order = await _context.Orders
            .FirstOrDefaultAsync(o => o.OrderId == orderId);

        if (order == null)
            throw new Exception("Không tìm thấy đơn hàng");

        if (order.Status == "paid")
            throw new Exception("Đơn hàng đã được thanh toán");

        // 2. Kiểm tra payment record
        var payment = await _context.Payments
            .FirstOrDefaultAsync(p => p.OrderId == orderId);

        if (payment == null)
        {
            payment = new Payment
            {
                PaymentId = GeneratePaymentId(),
                OrderId = orderId,
                Amount = order.FinalAmount,
                PaymentMethod = "sepay",
                PaymentStatus = "pending"
            };
            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();
        }
        else if (payment.PaymentStatus == "paid")
        {
            throw new Exception("Đơn hàng đã được thanh toán");
        }

        // 3. Kiểm tra pending transaction
        var pendingTrans = await _context.PendingTransactions
            .FirstOrDefaultAsync(p => p.OrderId == orderId && p.Status == "pending");

        if (pendingTrans == null)
        {
            pendingTrans = new PendingTransaction
            {
                OrderId = orderId,
                PaymentId = payment.PaymentId,
                Amount = order.FinalAmount,
                BankCode = "MB",
                Status = "pending",
                CheckCount = 0,
                CreatedAt = DateTime.Now
            };
            _context.PendingTransactions.Add(pendingTrans);
            await _context.SaveChangesAsync();
        }

        // 4. Tạo QR code
        var qrUrl = GenerateVietQRCode(orderId, order.FinalAmount);

        // 5. Cập nhật QR URL
        payment.QrCodeUrl = qrUrl;
        await _context.SaveChangesAsync();

        _logger.LogInformation($"Tạo QR thành công cho order {orderId}, payment {payment.PaymentId}");

        return new PaymentQRResponseDto
        {
            QrCodeUrl = qrUrl,
            PaymentId = payment.PaymentId,
            OrderId = orderId,
            Amount = order.FinalAmount,
            PaymentStatus = payment.PaymentStatus
        };
    }

    public async Task<PaymentStatusResponseDto> GetPaymentStatusAsync(string orderId)
    {
        // Lấy thông tin từ payment
        var payment = await _context.Payments
            .Where(p => p.OrderId == orderId)
            .Select(p => new PaymentStatusResponseDto
            {
                PaymentId = p.PaymentId,
                PaymentStatus = p.PaymentStatus,
                PaidAt = p.PaidAt,
                Amount = p.Amount,
                TransactionCode = p.TransactionCode,
                PaymentMethod = p.PaymentMethod
            })
            .FirstOrDefaultAsync();

        if (payment == null)
            throw new Exception("Không tìm thấy thông tin thanh toán");

        return payment;
    }

    public async Task<bool> ProcessSePayWebhookAsync(string orderId, decimal amount, string transactionCode, string content)
    {
        // Sử dụng transaction để đảm bảo atomic
        using var transaction = await _context.Database.BeginTransactionAsync();

        try
        {
            // 1. Tìm payment record
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.OrderId == orderId && p.PaymentStatus != "paid");

            if (payment == null)
            {
                _logger.LogWarning("Không tìm thấy payment record cho order {OrderId}", orderId);
                return false;
            }

            // 2. Kiểm tra số tiền
            if (payment.Amount != amount)
            {
                _logger.LogWarning("Số tiền không khớp: expected {Expected}, got {Actual}", payment.Amount, amount);
                return false;
            }

            // 3. Tìm và cập nhật pending transaction
            var pendingTrans = await _context.PendingTransactions
                .FirstOrDefaultAsync(p => p.OrderId == orderId && p.Status == "pending");

            if (pendingTrans != null)
            {
                pendingTrans.Status = "completed";
                pendingTrans.TransactionCode = transactionCode;
                pendingTrans.CheckedAt = DateTime.Now;
            }

            // 4. Cập nhật payment
            payment.PaymentStatus = "paid";
            payment.PaidAt = DateTime.UtcNow;
            payment.TransactionCode = transactionCode;
            payment.PaymentMethod = "sepay";

            // 5. Cập nhật order status - ĐỔI THÀNH "processing" thay vì "pending"
            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.OrderId == orderId);

            if (order == null)
            {
                _logger.LogWarning("Không tìm thấy order {OrderId}", orderId);
                await transaction.RollbackAsync();
                return false;
            }

            order.Status = "pending";

            // 6. KIỂM TRA STOCK LẦN CUỐI trước khi xác nhận
            var orderItems = await _context.OrderItems
                .Where(oi => oi.OrderId == orderId)
                .Include(oi => oi.Product)
                .ToListAsync();

            foreach (var item in orderItems)
            {
                if (item.Product == null)
                {
                    _logger.LogError($"Không tìm thấy sản phẩm {item.ProductId} cho order {orderId}");
                    await transaction.RollbackAsync();
                    return false;
                }

                // Kiểm tra stock lần cuối
                if (item.Product.StockQuantity < item.Quantity)
                {
                    _logger.LogWarning($"Sản phẩm {item.Product.ProductName} không đủ stock. Cần: {item.Quantity}, Còn: {item.Product.StockQuantity}");
                    await transaction.RollbackAsync();
                    return false;
                }

                // Trừ stock (nếu chưa trừ ở bước tạo order)
                // LƯU Ý: Nếu đã trừ stock khi tạo order thì comment đoạn này lại
                item.Product.StockQuantity -= item.Quantity;
                _logger.LogInformation($"Đã trừ stock sản phẩm {item.Product.ProductId}: -{item.Quantity}, còn lại: {item.Product.StockQuantity}");
            }

            // 7. XÓA CHỈ NHỮNG ITEMS ĐÃ ĐẶT HÀNG khỏi giỏ (không xóa toàn bộ)
            if (!string.IsNullOrEmpty(order.UserId))
            {
                var cart = await _context.Carts
                    .Include(c => c.CartItems)
                    .FirstOrDefaultAsync(c => c.UserId == order.UserId);

                if (cart != null && cart.CartItems != null && cart.CartItems.Any())
                {
                    // ✅ FIX: Chỉ xóa những items mà nằm trong order này
                    var orderedProductIds = orderItems.Select(oi => oi.ProductId).ToHashSet();
                    var itemsToRemove = cart.CartItems
                        .Where(ci => orderedProductIds.Contains(ci.ProductId))
                        .ToList();

                    if (itemsToRemove.Any())
                    {
                        _context.CartItems.RemoveRange(itemsToRemove);
                        cart.UpdatedAt = DateTime.UtcNow;
                        _logger.LogInformation($"✅ Đã xóa {itemsToRemove.Count} items đã đặt hàng khỏi giỏ. Order: {orderId}, User: {order.UserId}");
                    }
                }
                else
                {
                    _logger.LogInformation($"Giỏ hàng của user {order.UserId} đã trống hoặc không tồn tại");
                }
            }

            // 8. Lưu tất cả thay đổi
            await _context.SaveChangesAsync();

            // 9. Commit transaction
            await transaction.CommitAsync();

            _logger.LogInformation($"✅ Thanh toán thành công cho order {orderId}, payment {payment.PaymentId}. " +
                                   $"Đã trừ stock và xóa giỏ hàng.");

            return true;
        }
        catch (Exception ex)
        {
            // Rollback transaction nếu có lỗi
            await transaction.RollbackAsync();
            _logger.LogError(ex, $"Lỗi khi xử lý webhook thanh toán cho order {orderId}");
            return false;
        }
    }

    private string GenerateVietQRCode(string orderId, decimal amount)
    {
        var bankCode = _config["VietQR:BankCode"] ?? "MB";
        var accountNo = _config["VietQR:AccountNo"] ?? "123456789";
        var accountName = _config["VietQR:AccountName"] ?? "FRUIT MARKET SHOP";
        var template = _config["VietQR:Template"] ?? "compact2";

        var orderInfo = orderId;

        var qrUrl = $"https://img.vietqr.io/image/{bankCode}-{accountNo}-{template}.png?" +
                    $"amount={amount}&" +
                    $"addInfo={Uri.EscapeDataString(orderInfo)}&" +
                    $"accountName={Uri.EscapeDataString(accountName)}";

        return qrUrl;
    }

    private string GeneratePaymentId()
    {
        return "PAY" + DateTime.Now.ToString("yyMMddHHmmss") + new Random().Next(1000, 9999);
    }
}
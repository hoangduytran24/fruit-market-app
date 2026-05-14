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

        // 3. Tìm pending transaction
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

        // 5. Cập nhật order status
        var order = await _context.Orders.FindAsync(orderId);
        if (order != null)
        {
            order.Status = "paid";
        }

        await _context.SaveChangesAsync();

        _logger.LogInformation($"✅ Thanh toán thành công cho order {orderId}, payment {payment.PaymentId}");

        return true;
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
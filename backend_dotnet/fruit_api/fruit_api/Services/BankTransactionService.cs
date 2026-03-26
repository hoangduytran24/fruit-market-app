using fruit_api.Data;
using fruit_api.Models;
using Microsoft.EntityFrameworkCore;

namespace fruit_api.Services;

public class BankTransactionService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<BankTransactionService> _logger;

    public BankTransactionService(
        ApplicationDbContext context,
        ILogger<BankTransactionService> logger)
    {
        _context = context;
        _logger = logger;
    }

    // Thêm giao dịch vào danh sách chờ
    public async Task<PendingTransaction> AddPendingTransaction(
        string orderId,
        string paymentId,
        decimal amount)
    {
        var pending = new PendingTransaction
        {
            OrderId = orderId,
            PaymentId = paymentId,
            Amount = amount,
            Status = "pending",
            CheckCount = 0,
            CreatedAt = DateTime.Now
        };

        _context.PendingTransactions.Add(pending);
        await _context.SaveChangesAsync();

        _logger.LogInformation($"Added pending transaction for order {orderId}");

        return pending;
    }

    // Kiểm tra giao dịch (mô phỏng - tự động thành công sau 30 giây)
    public async Task<TransactionCheckResult> CheckTransaction(string orderId, decimal amount)
    {
        var pendingTx = await _context.PendingTransactions
            .FirstOrDefaultAsync(p => p.OrderId == orderId && p.Status == "pending");

        if (pendingTx == null)
        {
            return new TransactionCheckResult
            {
                Success = false,
                Message = "Không tìm thấy giao dịch",
                IsPending = false
            };
        }

        // Tăng số lần kiểm tra
        pendingTx.CheckCount++;
        pendingTx.CheckedAt = DateTime.Now;
        await _context.SaveChangesAsync();

        _logger.LogInformation($"Checking transaction for order {orderId}, count: {pendingTx.CheckCount}");

        // MÔ PHỎNG: Sau 6 lần kiểm tra (30 giây) thì tự động thành công
        // 6 lần x 5 giây = 30 giây
        if (pendingTx.CheckCount >= 6)
        {
            pendingTx.Status = "success";
            pendingTx.TransactionCode = "MOCK_" + DateTime.Now.Ticks.ToString();
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Transaction for order {orderId} completed successfully");

            return new TransactionCheckResult
            {
                Success = true,
                TransactionCode = pendingTx.TransactionCode,
                Message = "Đã nhận được thanh toán",
                IsPending = false
            };
        }

        return new TransactionCheckResult
        {
            Success = false,
            Message = "Chưa nhận được thanh toán",
            IsPending = true
        };
    }
}

// Class để trả về kết quả kiểm tra
public class TransactionCheckResult
{
    public bool Success { get; set; }
    public string? TransactionCode { get; set; }
    public string Message { get; set; } = null!;
    public bool IsPending { get; set; }
}
using fruit_api.Data;
using fruit_api.Models;
using fruit_api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace fruit_api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PaymentController : ControllerBase
{
    private readonly VietQRService _vietQRService;
    private readonly BankTransactionService _bankTransactionService;
    private readonly ApplicationDbContext _context;

    public PaymentController(
        VietQRService vietQRService,
        BankTransactionService bankTransactionService,
        ApplicationDbContext context)
    {
        _vietQRService = vietQRService;
        _bankTransactionService = bankTransactionService;
        _context = context;
    }

    // ==================== VIETQR ====================

    // Tạo thanh toán VietQR
    [HttpPost("vietqr/create")]
    public async Task<IActionResult> CreateVietQRPayment([FromBody] VietQRRequest request)
    {
        try
        {
            Console.WriteLine($"=== Create VietQR Payment ===");
            Console.WriteLine($"OrderId: {request?.OrderId}");

            // Kiểm tra request
            if (request == null || string.IsNullOrEmpty(request.OrderId))
            {
                return BadRequest(new { success = false, message = "OrderId không được để trống" });
            }

            // Kiểm tra đơn hàng
            var order = await _context.Orders
                .FirstOrDefaultAsync(o => o.OrderId == request.OrderId);

            if (order == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy đơn hàng" });
            }

            // Lấy số tiền
            decimal amount = order.FinalAmount > 0 ? order.FinalAmount : order.TotalAmount;

            if (amount <= 0)
            {
                return BadRequest(new { success = false, message = "Số tiền không hợp lệ" });
            }

            // Kiểm tra đã có payment chưa
            var existingPayment = await _context.Payments
                .FirstOrDefaultAsync(p => p.OrderId == request.OrderId);

            Payment payment;

            if (existingPayment != null)
            {
                payment = existingPayment;

                if (payment.PaymentStatus == "success")
                {
                    return BadRequest(new { success = false, message = "Đơn hàng đã được thanh toán" });
                }
            }
            else
            {
                // Tạo payment mới
                payment = new Payment
                {
                    PaymentId = GeneratePaymentId(),
                    OrderId = request.OrderId,
                    Amount = amount,
                    PaymentMethod = "VIETQR",
                    PaymentStatus = "pending"
                };

                _context.Payments.Add(payment);
                await _context.SaveChangesAsync();
            }

            // Tạo QR code
            var qrResult = _vietQRService.GenerateQR(request.OrderId, amount);

            // Lưu QR URL vào payment
            payment.QrCodeUrl = qrResult.QrCodeUrl;
            await _context.SaveChangesAsync();

            // Thêm vào danh sách chờ kiểm tra
            await _bankTransactionService.AddPendingTransaction(
                request.OrderId,
                payment.PaymentId,
                amount);

            Console.WriteLine($"Created payment: {payment.PaymentId}, Amount: {amount}");

            return Ok(new
            {
                success = true,
                paymentId = payment.PaymentId,
                qrCodeUrl = qrResult.QrCodeUrl,
                amount = amount,
                orderId = request.OrderId,
                message = "Tạo mã QR thành công"
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    // Kiểm tra trạng thái thanh toán (polling)
    [HttpGet("vietqr/check/{orderId}")]
    public async Task<IActionResult> CheckVietQRPayment(string orderId)
    {
        try
        {
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.OrderId == orderId);

            if (payment == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy payment" });
            }

            // Nếu đã thanh toán thành công
            if (payment.PaymentStatus == "success")
            {
                return Ok(new
                {
                    success = true,
                    status = "success",
                    paymentId = payment.PaymentId,
                    transactionCode = payment.TransactionCode,
                    message = "Thanh toán thành công!"
                });
            }

            // Kiểm tra giao dịch
            var checkResult = await _bankTransactionService.CheckTransaction(orderId, payment.Amount);

            if (checkResult.Success)
            {
                // Cập nhật payment thành công
                payment.PaymentStatus = "success";
                payment.TransactionCode = checkResult.TransactionCode;
                payment.PaidAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                // Cập nhật order status
                var order = await _context.Orders.FindAsync(orderId);
                if (order != null)
                {
                    order.Status = "paid";
                    await _context.SaveChangesAsync();
                }

                Console.WriteLine($"Payment {payment.PaymentId} completed successfully");

                return Ok(new
                {
                    success = true,
                    status = "success",
                    paymentId = payment.PaymentId,
                    transactionCode = checkResult.TransactionCode,
                    message = "Thanh toán thành công!"
                });
            }

            // Chưa có thanh toán
            return Ok(new
            {
                success = false,
                status = "pending",
                paymentId = payment.PaymentId,
                message = checkResult.Message,
                isPending = checkResult.IsPending
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error checking payment: {ex.Message}");
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    // Helper: Tạo PaymentId
    private string GeneratePaymentId()
    {
        return "PM" + DateTime.Now.ToString("yyMMddHHmmss") + new Random().Next(1000, 9999);
    }
}

// Request model
public class VietQRRequest
{
    public string OrderId { get; set; } = null!;
}
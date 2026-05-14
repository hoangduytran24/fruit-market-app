using fruit_api.Data;
using fruit_api.DTOs.Payment;
using fruit_api.Models;
using fruit_api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.RegularExpressions;

namespace fruit_api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PaymentController : ControllerBase
{
    private readonly VietQRService _vietQRService;
    private readonly BankTransactionService _bankTransactionService;
    private readonly ApplicationDbContext _context;
    private readonly ILogger<PaymentController> _logger;

    public PaymentController(
        VietQRService vietQRService,
        BankTransactionService bankTransactionService,
        ApplicationDbContext context,
        ILogger<PaymentController> logger)
    {
        _vietQRService = vietQRService;
        _bankTransactionService = bankTransactionService;
        _context = context;
        _logger = logger;
    }


    /// <summary>
    /// Tạo thanh toán VietQR
    /// </summary>
    [HttpPost("vietqr/create")]
    public async Task<IActionResult> CreateVietQRPayment([FromBody] VietQRRequest request)
    {
        try
        {
            Console.WriteLine($"=== Create VietQR Payment ===");
            Console.WriteLine($"OrderId: {request?.OrderId}");

            if (request == null || string.IsNullOrEmpty(request.OrderId))
            {
                return BadRequest(new { success = false, message = "OrderId không được để trống" });
            }

            var order = await _context.Orders
                .FirstOrDefaultAsync(o => o.OrderId == request.OrderId);

            if (order == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy đơn hàng" });
            }

            decimal amount = order.FinalAmount > 0 ? order.FinalAmount : order.TotalAmount;

            if (amount <= 0)
            {
                return BadRequest(new { success = false, message = "Số tiền không hợp lệ" });
            }

            var existingPayment = await _context.Payments
                .FirstOrDefaultAsync(p => p.OrderId == request.OrderId);

            Payment payment;

            if (existingPayment != null)
            {
                payment = existingPayment;

                if (payment.PaymentStatus == "paid")
                {
                    return BadRequest(new { success = false, message = "Đơn hàng đã được thanh toán" });
                }
            }
            else
            {
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

            var qrResult = _vietQRService.GenerateQR(request.OrderId, amount);

            payment.QrCodeUrl = qrResult.QrCodeUrl;
            await _context.SaveChangesAsync();

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

    /// <summary>
    /// Kiểm tra trạng thái thanh toán VietQR (polling)
    /// </summary>
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

            if (payment.PaymentStatus == "paid")
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

            var checkResult = await _bankTransactionService.CheckTransaction(orderId, payment.Amount);

            if (checkResult.Success)
            {
                payment.PaymentStatus = "paid";
                payment.TransactionCode = checkResult.TransactionCode;
                payment.PaidAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

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


    /// <summary>
    /// Tạo thanh toán với SePay (hiển thị QR)
    /// </summary>
    [HttpPost("sepay/create")]
    public async Task<IActionResult> CreateSePayPayment([FromBody] VietQRRequest request)
    {
        try
        {
            _logger.LogInformation("=== Create SePay Payment ===");
            _logger.LogInformation($"OrderId: {request?.OrderId}");

            if (request == null || string.IsNullOrEmpty(request.OrderId))
            {
                return BadRequest(new { success = false, message = "OrderId không được để trống" });
            }

            // Kiểm tra đơn hàng
            var order = await _context.Orders
                .FirstOrDefaultAsync(o => o.OrderId == request.OrderId);

            if (order == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy đơn hàng" });
            }

            if (order.Status == "paid")
            {
                return BadRequest(new { success = false, message = "Đơn hàng đã được thanh toán" });
            }

            decimal amount = order.FinalAmount > 0 ? order.FinalAmount : order.TotalAmount;

            if (amount <= 0)
            {
                return BadRequest(new { success = false, message = "Số tiền không hợp lệ" });
            }

            // Kiểm tra payment record
            var existingPayment = await _context.Payments
                .FirstOrDefaultAsync(p => p.OrderId == request.OrderId);

            Payment payment;

            if (existingPayment != null)
            {
                payment = existingPayment;
                if (payment.PaymentStatus == "paid")
                {
                    return BadRequest(new { success = false, message = "Đơn hàng đã được thanh toán" });
                }
            }
            else
            {
                payment = new Payment
                {
                    PaymentId = GeneratePaymentId(),
                    OrderId = request.OrderId,
                    Amount = amount,
                    PaymentMethod = "SEPAY",
                    PaymentStatus = "pending"
                };
                _context.Payments.Add(payment);
                await _context.SaveChangesAsync();
            }

            // Tạo QR code (dùng VietQR service)
            var qrResult = _vietQRService.GenerateQR(request.OrderId, amount);
            payment.QrCodeUrl = qrResult.QrCodeUrl;
            await _context.SaveChangesAsync();

            // Thêm vào pending transactions
            var existingPending = await _context.PendingTransactions
                .FirstOrDefaultAsync(p => p.OrderId == request.OrderId && p.Status == "pending");

            if (existingPending == null)
            {
                var pendingTrans = new PendingTransaction
                {
                    OrderId = request.OrderId,
                    PaymentId = payment.PaymentId,
                    Amount = amount,
                    BankCode = "MB",
                    Status = "pending",
                    CheckCount = 0,
                    CreatedAt = DateTime.Now
                };
                _context.PendingTransactions.Add(pendingTrans);
                await _context.SaveChangesAsync();
            }

            _logger.LogInformation($"Created SePay payment: {payment.PaymentId}, Amount: {amount}");

            return Ok(new
            {
                success = true,
                paymentId = payment.PaymentId,
                qrCodeUrl = qrResult.QrCodeUrl,
                amount = amount,
                orderId = request.OrderId,
                message = "Tạo mã QR thành công. Vui lòng quét mã để thanh toán."
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating SePay payment");
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    /// <summary>
    /// Kiểm tra trạng thái thanh toán SePay (polling)
    /// </summary>
    [HttpGet("sepay/status/{orderId}")]
    public async Task<IActionResult> GetSePayPaymentStatus(string orderId)
    {
        try
        {
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.OrderId == orderId);

            if (payment == null)
            {
                return Ok(new
                {
                    success = false,
                    status = "not_found",
                    message = "Không tìm thấy thông tin thanh toán"
                });
            }

            if (payment.PaymentStatus == "paid")
            {
                var order = await _context.Orders.FindAsync(orderId);
                return Ok(new
                {
                    success = true,
                    status = "paid",
                    paymentId = payment.PaymentId,
                    transactionCode = payment.TransactionCode,
                    paidAt = payment.PaidAt,
                    amount = payment.Amount,
                    orderStatus = order?.Status,
                    message = "Thanh toán thành công!"
                });
            }

            return Ok(new
            {
                success = false,
                status = "pending",
                paymentId = payment.PaymentId,
                amount = payment.Amount,
                message = "Chờ thanh toán. Vui lòng quét mã QR để hoàn tất."
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking SePay payment status");
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    /// <summary>
    /// Lấy thông tin chi tiết payment
    /// </summary>
    [HttpGet("info/{paymentId}")]
    public async Task<IActionResult> GetPaymentInfo(string paymentId)
    {
        try
        {
            var payment = await _context.Payments
                .Include(p => p.Order)
                .FirstOrDefaultAsync(p => p.PaymentId == paymentId);

            if (payment == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy payment" });
            }

            return Ok(new
            {
                success = true,
                data = new
                {
                    payment.PaymentId,
                    payment.OrderId,
                    payment.Amount,
                    payment.PaymentMethod,
                    payment.PaymentStatus,
                    payment.TransactionCode,
                    payment.QrCodeUrl,
                    payment.PaidAt,
                    orderStatus = payment.Order?.Status
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting payment info");
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
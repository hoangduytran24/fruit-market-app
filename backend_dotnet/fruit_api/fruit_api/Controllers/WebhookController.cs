using Microsoft.AspNetCore.Mvc;
using fruit_api.DTOs.Payment;
using fruit_api.Services.Interfaces;
using System.Text.RegularExpressions;

namespace fruit_api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WebhookController : ControllerBase
{
    private readonly IPaymentService _paymentService;
    private readonly ILogger<WebhookController> _logger;

    public WebhookController(IPaymentService paymentService, ILogger<WebhookController> logger)
    {
        _paymentService = paymentService;
        _logger = logger;
    }

    /// <summary>
    /// SePay gọi webhook này khi có giao dịch chuyển khoản
    /// </summary>
    [HttpPost("sepay")]
    public async Task<IActionResult> SePayWebhook([FromBody] SePayWebhookDto webhookData)
    {
        try
        {
            _logger.LogInformation("=== SePay Webhook Received ===");
            _logger.LogInformation($"Content: {webhookData.Content}");
            _logger.LogInformation($"Amount: {webhookData.TransferAmount}");
            _logger.LogInformation($"ReferenceCode: {webhookData.ReferenceCode}");

            var content = webhookData.Content ?? "";
            var amount = webhookData.TransferAmount;
            var transactionCode = !string.IsNullOrEmpty(webhookData.ReferenceCode)
                ? webhookData.ReferenceCode
                : webhookData.Code;

            // Trích xuất OrderId từ nội dung (GUID format)
            var orderIdMatch = Regex.Match(content,
                @"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}");

            if (!orderIdMatch.Success)
            {
                _logger.LogWarning("Không tìm thấy OrderId trong nội dung: {Content}", content);
                return Ok(new { success = true, message = "No order id found" });
            }

            var orderId = orderIdMatch.Value;
            _logger.LogInformation($"Found OrderId: {orderId}");

            // Xử lý thanh toán
            var result = await _paymentService.ProcessSePayWebhookAsync(orderId, amount, transactionCode, content);

            if (result)
            {
                _logger.LogInformation($"✅ Xử lý thành công cho order {orderId}");
                return Ok(new { success = true, message = "Payment confirmed" });
            }
            else
            {
                _logger.LogWarning($"❌ Xử lý thất bại cho order {orderId}");
                return Ok(new { success = true, message = "Payment validation failed" });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi xử lý webhook SePay");
            // Luôn trả về success để SePay không gửi lại
            return Ok(new { success = true, message = "Error but acknowledged" });
        }
    }
}
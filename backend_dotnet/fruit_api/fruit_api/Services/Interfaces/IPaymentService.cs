using fruit_api.DTOs.Payment;

namespace fruit_api.Services.Interfaces;

public interface IPaymentService
{
    Task<PaymentQRResponseDto> GeneratePaymentQRAsync(string orderId);
    Task<PaymentStatusResponseDto> GetPaymentStatusAsync(string orderId);
    Task<bool> ProcessSePayWebhookAsync(string orderId, decimal amount, string transactionCode, string content);
}
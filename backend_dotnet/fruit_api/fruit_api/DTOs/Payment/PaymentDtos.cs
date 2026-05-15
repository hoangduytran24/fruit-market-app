namespace fruit_api.DTOs.Payment;

public class CreatePaymentQRDto
{
    public string OrderId { get; set; } = string.Empty;
}

public class PaymentQRResponseDto
{
    public string QrCodeUrl { get; set; } = string.Empty;
    public string PaymentId { get; set; } = string.Empty;
    public string OrderId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string PaymentStatus { get; set; } = string.Empty;
}

public class PaymentStatusResponseDto
{
    public string PaymentId { get; set; } = string.Empty;
    public string PaymentStatus { get; set; } = string.Empty;
    public DateTime? PaidAt { get; set; }
    public decimal Amount { get; set; }
    public string? TransactionCode { get; set; }
    public string? PaymentMethod { get; set; }
}

public class SePayWebhookDto
{
    public long Id { get; set; }
    public string Gateway { get; set; } = string.Empty;
    public string TransactionDate { get; set; } = string.Empty;
    public string AccountNumber { get; set; } = string.Empty;

    // QUAN TRỌNG: Cho phép Code = null (dùng string? thay vì string)
    public string? Code { get; set; } = null!;

    public string Content { get; set; } = string.Empty;
    public decimal TransferAmount { get; set; }
    public string ReferenceCode { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}
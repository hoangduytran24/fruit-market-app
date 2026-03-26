namespace fruit_api.Models;

public class VietQRRequest
{
    public string OrderId { get; set; } = null!;
}

public class VietQRResponse
{
    public bool Success { get; set; }
    public string QrCodeUrl { get; set; } = null!;
    public string PaymentId { get; set; } = null!;
    public decimal Amount { get; set; }
    public string Message { get; set; } = null!;
}

public class TransactionCheckResult
{
    public bool Success { get; set; }
    public string? TransactionCode { get; set; }
    public string Message { get; set; } = null!;
    public bool IsPending { get; set; }
}
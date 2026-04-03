namespace fruit_api.DTOs.RealTime
{
    public class RealTimeUpdateDto
    {
        public string EventType { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public object? Data { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public string? UserId { get; set; }
    }

    public class OrderStatusUpdateDto
    {
        public string OrderId { get; set; } = string.Empty;
        public string? OrderCode { get; set; }
        public string OldStatus { get; set; } = string.Empty;
        public string NewStatus { get; set; } = string.Empty;
        public DateTime UpdatedAt { get; set; } = DateTime.Now;
        public string? UpdatedBy { get; set; }
        public decimal? TotalAmount { get; set; }
    }

    public class PaymentUpdateDto
    {
        public string OrderId { get; set; } = string.Empty;
        public string? OrderCode { get; set; }
        public string PaymentStatus { get; set; } = string.Empty;
        public string? TransactionId { get; set; }
        public DateTime PaymentTime { get; set; } = DateTime.Now;
    }

    public class NewOrderNotificationDto
    {
        public string OrderId { get; set; } = string.Empty;
        public string OrderCode { get; set; } = string.Empty;
        public string CustomerName { get; set; } = string.Empty;
        public decimal TotalAmount { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}
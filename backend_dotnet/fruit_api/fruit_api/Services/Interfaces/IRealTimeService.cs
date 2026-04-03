using fruit_api.DTOs.RealTime;

namespace fruit_api.Services.Interfaces
{
    public interface IRealTimeService
    {
        // Gửi thông báo đến user cụ thể qua group "user_{userId}"
        Task NotifyUserAsync(string userId, string eventType, string message, object? data = null);

        // Gửi thông báo đến group đơn hàng "order_{orderId}"
        // Chuyển int -> string để khớp với Hub
        Task NotifyOrderGroupAsync(string orderId, string eventType, string message, object? data = null);

        // Gửi thông báo đến tất cả admin (group "admins")
        Task NotifyAdminsAsync(string eventType, string message, object? data = null);

        // --- Các method đặc thù cho business ---

        // Thông báo trạng thái đơn hàng thay đổi
        Task NotifyOrderStatusChangedAsync(string orderId, string userId, string oldStatus, string newStatus, string? orderCode = null);

        // Thông báo trạng thái thanh toán thay đổi
        Task NotifyPaymentStatusChangedAsync(string orderId, string userId, string paymentStatus, string? transactionId = null);

        // Thông báo có đơn hàng mới cho Admin
        Task NotifyNewOrderToAdminsAsync(NewOrderNotificationDto orderInfo);
    }
}
using Microsoft.AspNetCore.SignalR;
using fruit_api.DTOs.RealTime;
using fruit_api.Hubs;
using fruit_api.Services.Interfaces;

namespace fruit_api.Services
{
    public class RealTimeService : IRealTimeService
    {
        private readonly IHubContext<OrderHub> _hubContext;
        private readonly ILogger<RealTimeService> _logger;

        public RealTimeService(
            IHubContext<OrderHub> hubContext,
            ILogger<RealTimeService> logger)
        {
            _hubContext = hubContext;
            _logger = logger;
        }

        public async Task NotifyUserAsync(string userId, string eventType, string message, object? data = null)
        {
            try
            {
                var update = new RealTimeUpdateDto
                {
                    EventType = eventType,
                    Message = message,
                    Data = data,
                    Timestamp = DateTime.UtcNow, // Dùng Utc cho đồng bộ
                    UserId = userId
                };

                // Gửi tới group riêng của User: "user_{userId}"
                var groupName = $"user_{userId}";
                await _hubContext.Clients.Group(groupName).SendAsync("ReceiveRealTimeUpdate", update);

                _logger.LogInformation($"[SignalR] Sent {eventType} to user group {groupName}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"[SignalR] Error sending notification to user {userId}");
            }
        }

        public async Task NotifyOrderGroupAsync(string orderId, string eventType, string message, object? data = null)
        {
            try
            {
                var update = new RealTimeUpdateDto
                {
                    EventType = eventType,
                    Message = message,
                    Data = data,
                    Timestamp = DateTime.UtcNow
                };

                var groupName = $"order_{orderId}";
                await _hubContext.Clients.Group(groupName).SendAsync("ReceiveRealTimeUpdate", update);
                _logger.LogInformation($"[SignalR] Sent {eventType} to order group {groupName}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"[SignalR] Error sending notification to order group {orderId}");
            }
        }

        public async Task NotifyAdminsAsync(string eventType, string message, object? data = null)
        {
            try
            {
                var update = new RealTimeUpdateDto
                {
                    EventType = eventType,
                    Message = message,
                    Data = data,
                    Timestamp = DateTime.UtcNow
                };

                await _hubContext.Clients.Group("admins").SendAsync("ReceiveRealTimeUpdate", update);
                _logger.LogInformation($"[SignalR] Sent {eventType} to admins group");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[SignalR] Error sending notification to admins");
            }
        }

        // --- Business Methods ---

        public async Task NotifyOrderStatusChangedAsync(string orderId, string userId, string oldStatus, string newStatus, string? orderCode = null)
        {
            var orderUpdate = new OrderStatusUpdateDto
            {
                OrderId = orderId,
                OrderCode = orderCode,
                OldStatus = oldStatus,
                NewStatus = newStatus,
                UpdatedAt = DateTime.Now,
                UpdatedBy = "Hệ thống"
            };

            var displayId = orderCode ?? orderId;
            var message = $"Đơn hàng {displayId} đã chuyển sang trạng thái: {newStatus}";

            // 1. Gửi cho User sở hữu đơn hàng
            await NotifyUserAsync(userId, "OrderStatusChanged", message, orderUpdate);

            // 2. Gửi cho những người đang theo dõi đơn hàng này (nếu có)
            await NotifyOrderGroupAsync(orderId, "OrderStatusChanged", message, orderUpdate);
        }

        public async Task NotifyPaymentStatusChangedAsync(string orderId, string userId, string paymentStatus, string? transactionId = null)
        {
            var paymentUpdate = new PaymentUpdateDto
            {
                OrderId = orderId,
                PaymentStatus = paymentStatus,
                TransactionId = transactionId,
                PaymentTime = DateTime.Now
            };

            await NotifyUserAsync(
                userId,
                "PaymentStatusChanged",
                $"Kết quả thanh toán đơn hàng {orderId}: {paymentStatus}",
                paymentUpdate
            );
        }

        public async Task NotifyNewOrderToAdminsAsync(NewOrderNotificationDto orderInfo)
        {
            await NotifyAdminsAsync(
                "NewOrder",
                $"🔔 Đơn hàng mới: {orderInfo.OrderCode} - {orderInfo.TotalAmount:N0}đ",
                orderInfo
            );
        }
    }
}
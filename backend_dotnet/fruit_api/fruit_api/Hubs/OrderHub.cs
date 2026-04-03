using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace fruit_api.Hubs
{
    [Authorize]
    public class OrderHub : Hub
    {
        private readonly ILogger<OrderHub> _logger;

        public OrderHub(ILogger<OrderHub> logger)
        {
            _logger = logger;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = Context.UserIdentifier;
            var userRole = Context.User?.Claims?.FirstOrDefault(c => c.Type == ClaimTypes.Role)?.Value;

            _logger.LogInformation($"User {userId} (Role: {userRole}) connected with connection ID: {Context.ConnectionId}");

            if (!string.IsNullOrEmpty(userId))
            {
                // Tự động thêm vào group cá nhân khi kết nối
                await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");

                // Nếu là admin, thêm vào group admins
                if (userRole?.ToLower() == "admin")
                {
                    await Groups.AddToGroupAsync(Context.ConnectionId, "admins");
                    _logger.LogInformation($"User {userId} joined admins group");
                }
            }

            await base.OnConnectedAsync();
        }

        // Fix lỗi "Method does not exist" cho Flutter
        public async Task JoinUserGroup(string userId)
        {
            var currentUserId = Context.UserIdentifier;
            // Chỉ cho phép join group của chính mình
            if (currentUserId == userId)
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
                _logger.LogInformation($"User {userId} explicitly joined their private group");
            }
            else
            {
                _logger.LogWarning($"User {currentUserId} tried to join group of user {userId}");
            }
        }

        public async Task JoinOrderGroup(string orderId)
        {
            var groupName = $"order_{orderId}";
            await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
            _logger.LogInformation($"User {Context.UserIdentifier} joined group {groupName}");
        }

        public async Task LeaveOrderGroup(string orderId)
        {
            var groupName = $"order_{orderId}";
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);
            _logger.LogInformation($"User {Context.UserIdentifier} left group {groupName}");
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.UserIdentifier;
            if (exception != null)
            {
                _logger.LogError(exception, $"User {userId} disconnected with error");
            }
            else
            {
                _logger.LogInformation($"User {userId} disconnected");
            }

            await base.OnDisconnectedAsync(exception);
        }
    }
}
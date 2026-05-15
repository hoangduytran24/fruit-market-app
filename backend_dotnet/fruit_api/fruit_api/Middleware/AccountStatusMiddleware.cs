// Middleware/AccountStatusMiddleware.cs
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using fruit_api.Data;

namespace fruit_api.Middleware;

public class AccountStatusMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<AccountStatusMiddleware> _logger;

    public AccountStatusMiddleware(RequestDelegate next, ILogger<AccountStatusMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, ApplicationDbContext dbContext)
    {
        // Bỏ qua các endpoint không cần kiểm tra
        var skipPaths = new[]
        {
            "/api/auth/login",
            "/api/auth/register",
            "/api/auth/refresh-token",
            "/api/auth/check-status", // Endpoint check status riêng
            "/swagger",
            "/health"
        };

        // Kiểm tra nếu đường dẫn hiện tại cần bỏ qua
        if (skipPaths.Any(path => context.Request.Path.StartsWithSegments(path, StringComparison.OrdinalIgnoreCase)))
        {
            await _next(context);
            return;
        }

        // Lấy userId từ claims (đã được xác thực qua JWT)
        var userId = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (!string.IsNullOrEmpty(userId))
        {
            try
            {
                // Kiểm tra trạng thái tài khoản từ database
                var user = await dbContext.Users
                    .Where(u => u.UserId == userId)
                    .Select(u => new { u.Status, u.FullName })
                    .FirstOrDefaultAsync();

                if (user == null)
                {
                    _logger.LogWarning($"Không tìm thấy user {userId} trong database");

                    context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                    await context.Response.WriteAsJsonAsync(new
                    {
                        success = false,
                        message = "Tài khoản không tồn tại",
                        code = "USER_NOT_FOUND"
                    });
                    return;
                }

                // Kiểm tra nếu tài khoản bị khóa (status != "active")
                if (user.Status != "active")
                {
                    _logger.LogWarning($"Tài khoản {userId} ({user.FullName}) đã bị khóa (status: {user.Status}) - Path: {context.Request.Method} {context.Request.Path}");

                    context.Response.StatusCode = StatusCodes.Status403Forbidden;
                    await context.Response.WriteAsJsonAsync(new
                    {
                        success = false,
                        message = "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ để biết thêm chi tiết.",
                        code = "ACCOUNT_LOCKED",
                        status = user.Status
                    });
                    return;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Lỗi khi kiểm tra trạng thái tài khoản cho user {userId}");
                // Vẫn cho phép request đi tiếp nếu có lỗi database để tránh gián đoạn
            }
        }

        await _next(context);
    }
}
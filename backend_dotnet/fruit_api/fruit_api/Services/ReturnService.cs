using Microsoft.EntityFrameworkCore;
using fruit_api.Data;
using fruit_api.Models;
using fruit_api.DTOs;
using fruit_api.Services.Interfaces;

namespace fruit_api.Services;

public class ReturnService : IReturnService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ReturnService> _logger;
    private readonly IRealTimeService _realTimeService;
    private readonly IFileUploadService _fileUploadService;

    public ReturnService(
        ApplicationDbContext context,
        ILogger<ReturnService> logger,
        IRealTimeService realTimeService,
        IFileUploadService fileUploadService)
    {
        _context = context;
        _logger = logger;
        _realTimeService = realTimeService;
        _fileUploadService = fileUploadService;
    }

    // 1. Kiểm tra đơn hàng có được trả không
    public async Task<bool> CanReturnOrderAsync(string userId, string orderId)
    {
        try
        {
            var order = await _context.Orders
                .FirstOrDefaultAsync(o => o.OrderId == orderId && o.UserId == userId);

            if (order == null) return false;

            // Điều kiện 1: Đơn hàng phải là 'completed'
            if (order.Status != "completed") return false;

            // Điều kiện 2: Phải có completedAt
            if (order.CompletedAt == null) return false;

            // Điều kiện 3: Còn trong thời gian 7 ngày kể từ ngày nhận hàng
            var daysDiff = (DateTime.Now - order.CompletedAt.Value).Days;
            if (daysDiff > 7) return false;

            // Điều kiện 4: Chưa có yêu cầu trả hàng nào đang pending hoặc approved
            var existingReturn = await _context.ReturnRequests
                .AnyAsync(r => r.OrderId == orderId &&
                              (r.Status == "pending" || r.Status == "approved"));

            return !existingReturn;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi kiểm tra điều kiện trả hàng");
            return false;
        }
    }

    // 2. Tạo yêu cầu trả hàng
    public async Task<ReturnRequestResponseDto?> CreateReturnRequestAsync(string userId, CreateReturnRequestDto dto)
    {
        try
        {
            // Kiểm tra quyền trả hàng
            var canReturn = await CanReturnOrderAsync(userId, dto.OrderId);
            if (!canReturn)
                throw new Exception("Đơn hàng không đủ điều kiện trả hàng");

            // Lấy thông tin order để biết số tiền hoàn lại
            var order = await _context.Orders
                .FirstOrDefaultAsync(o => o.OrderId == dto.OrderId);

            if (order == null)
                throw new Exception("Không tìm thấy đơn hàng");

            // Lưu trạng thái cũ để gửi notification
            var oldStatus = order.Status;

            // Xử lý upload ảnh nếu có file
            string? imageUrl = dto.ImageUrl;
            if (dto.ImageFile != null)
            {
                imageUrl = await _fileUploadService.UploadImageAsync(dto.ImageFile, "returns");
            }

            // Tạo yêu cầu trả hàng
            var returnRequest = new ReturnRequest
            {
                ReturnId = GenerateReturnId(),
                OrderId = dto.OrderId,
                UserId = userId,
                Reason = dto.Reason,
                Description = dto.Description,
                ImageUrl = imageUrl,
                Status = "pending",
                RefundAmount = order.FinalAmount,
                CreatedAt = DateTime.Now
            };

            _context.ReturnRequests.Add(returnRequest);

            // Cập nhật trạng thái đơn hàng thành return_requested
            order.Status = "return_requested";

            await _context.SaveChangesAsync();

            // Gửi notification realtime cho user
            await _realTimeService.NotifyOrderStatusChangedAsync(
                orderId: order.OrderId,
                userId: userId,
                oldStatus: oldStatus,
                newStatus: "return_requested",
                orderCode: order.OrderId
            );

            // Gửi notification cho admin
            await _realTimeService.NotifyAdminsAsync(
                "NewReturnRequest",
                $"🔄 Yêu cầu trả hàng mới từ đơn {order.OrderId}",
                new { ReturnId = returnRequest.ReturnId, OrderId = order.OrderId, UserId = userId, HasImage = imageUrl != null }
            );

            _logger.LogInformation($"Return request created for order {order.OrderId}, has image: {imageUrl != null}");

            return MapToResponseDto(returnRequest);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi tạo yêu cầu trả hàng");
            throw;
        }
    }

    // 3. Admin xử lý yêu cầu (duyệt/từ chối)
    public async Task<ReturnRequestResponseDto?> ProcessReturnRequestAsync(string adminId, ProcessReturnRequestDto dto)
    {
        try
        {
            var returnRequest = await _context.ReturnRequests
                .Include(r => r.Order)
                .FirstOrDefaultAsync(r => r.ReturnId == dto.ReturnId);

            if (returnRequest == null)
                throw new Exception("Không tìm thấy yêu cầu trả hàng");

            if (returnRequest.Status != "pending")
                throw new Exception("Yêu cầu này đã được xử lý");

            // Lưu trạng thái cũ để gửi notification
            var oldStatus = returnRequest.Order?.Status ?? "return_requested";
            string newStatus;

            if (dto.IsApproved)
            {
                // CHẤP NHẬN trả hàng
                returnRequest.Status = "approved";
                returnRequest.ApprovedAt = DateTime.Now;
                newStatus = "return_approved";

                // Cập nhật trạng thái đơn hàng thành return_approved
                if (returnRequest.Order != null)
                {
                    returnRequest.Order.Status = newStatus;
                }
            }
            else
            {
                // TỪ CHỐI trả hàng
                returnRequest.Status = "rejected";
                returnRequest.RejectedAt = DateTime.Now;
                returnRequest.RejectReason = dto.RejectReason;
                newStatus = "completed";

                // Khôi phục trạng thái đơn hàng về completed
                if (returnRequest.Order != null)
                {
                    returnRequest.Order.Status = newStatus;
                }
            }

            await _context.SaveChangesAsync();

            // Gửi notification realtime cho user
            if (returnRequest.Order != null)
            {
                await _realTimeService.NotifyOrderStatusChangedAsync(
                    orderId: returnRequest.Order.OrderId,
                    userId: returnRequest.UserId,
                    oldStatus: oldStatus,
                    newStatus: newStatus,
                    orderCode: returnRequest.Order.OrderId
                );
            }

            _logger.LogInformation($"Return request {returnRequest.ReturnId} processed: {oldStatus} -> {newStatus}");

            return MapToResponseDto(returnRequest);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi xử lý yêu cầu trả hàng");
            throw;
        }
    }

    // 4. Admin xác nhận đã nhận lại hàng (Cập nhật tồn kho)
    public async Task<ReturnRequestResponseDto?> CompleteReturnAsync(string returnId)
    {
        try
        {
            var returnRequest = await _context.ReturnRequests
                .Include(r => r.Order)
                    .ThenInclude(o => o!.OrderItems)      // THÊM: Lấy OrderItems
                        .ThenInclude(oi => oi!.Product)    // THÊM: Lấy Product để cập nhật stock
                .Include(r => r.Order)
                    .ThenInclude(o => o!.Payment)
                .FirstOrDefaultAsync(r => r.ReturnId == returnId);

            if (returnRequest == null)
                throw new Exception("Không tìm thấy yêu cầu trả hàng");

            if (returnRequest.Status != "approved")
                throw new Exception("Yêu cầu chưa được duyệt hoặc không hợp lệ");

            // Lưu trạng thái cũ để gửi notification
            var oldStatus = returnRequest.Order?.Status ?? "return_approved";
            var newStatus = "returned";

            // Cập nhật trạng thái yêu cầu
            returnRequest.Status = "completed";
            returnRequest.CompletedAt = DateTime.Now;

            // Cập nhật trạng thái đơn hàng thành returned
            if (returnRequest.Order != null)
            {
                returnRequest.Order.Status = newStatus;

                // Cập nhật trạng thái thanh toán thành refunded (hoàn tiền)
                if (returnRequest.Order.Payment != null)
                {
                    returnRequest.Order.Payment.PaymentStatus = "refunded";
                }

                // ✅ THÊM: Cập nhật lại tồn kho cho các sản phẩm
                if (returnRequest.Order.OrderItems != null && returnRequest.Order.OrderItems.Any())
                {
                    foreach (var orderItem in returnRequest.Order.OrderItems)
                    {
                        if (orderItem.Product != null)
                        {
                            // Cộng lại số lượng đã bán vào tồn kho
                            orderItem.Product.StockQuantity += orderItem.Quantity;
                            _logger.LogInformation($"Restocked product {orderItem.ProductId}: +{orderItem.Quantity}, new stock: {orderItem.Product.StockQuantity}");
                        }
                        else
                        {
                            // Nếu Product không được Include, fetch riêng
                            var product = await _context.Products.FindAsync(orderItem.ProductId);
                            if (product != null)
                            {
                                product.StockQuantity += orderItem.Quantity;
                                _logger.LogInformation($"Restocked product {product.ProductId}: +{orderItem.Quantity}, new stock: {product.StockQuantity}");
                            }
                        }
                    }
                }
            }

            await _context.SaveChangesAsync();

            // Gửi notification realtime cho user
            if (returnRequest.Order != null)
            {
                await _realTimeService.NotifyOrderStatusChangedAsync(
                    orderId: returnRequest.Order.OrderId,
                    userId: returnRequest.UserId,
                    oldStatus: oldStatus,
                    newStatus: newStatus,
                    orderCode: returnRequest.Order.OrderId
                );
            }

            _logger.LogInformation($"Return completed for order {returnRequest.Order?.OrderId}, status: returned, stock updated");

            return MapToResponseDto(returnRequest);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi xác nhận nhận lại hàng");
            throw;
        }
    }

    // 5. Lấy chi tiết yêu cầu trả hàng
    public async Task<ReturnRequestResponseDto?> GetReturnRequestByIdAsync(string returnId, string userId, string? role)
    {
        try
        {
            var returnRequest = await _context.ReturnRequests
                .FirstOrDefaultAsync(r => r.ReturnId == returnId);

            if (returnRequest == null) return null;

            // Kiểm tra quyền: user chỉ xem được của mình, admin xem được tất cả
            if (role != "admin" && returnRequest.UserId != userId)
                return null;

            return MapToResponseDto(returnRequest);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy chi tiết yêu cầu trả hàng");
            return null;
        }
    }

    // 6. Lấy danh sách yêu cầu của user hiện tại
    public async Task<List<ReturnRequestResponseDto>> GetUserReturnRequestsAsync(string userId)
    {
        try
        {
            var returns = await _context.ReturnRequests
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return returns.Select(MapToResponseDto).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy danh sách yêu cầu trả hàng của user");
            return new List<ReturnRequestResponseDto>();
        }
    }

    // 7. Admin lấy tất cả yêu cầu trả hàng
    public async Task<List<ReturnRequestResponseDto>> GetAllReturnRequestsAsync(string? status = null)
    {
        try
        {
            var query = _context.ReturnRequests.AsQueryable();

            if (!string.IsNullOrEmpty(status))
                query = query.Where(r => r.Status == status);

            var returns = await query
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return returns.Select(MapToResponseDto).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy danh sách tất cả yêu cầu trả hàng");
            return new List<ReturnRequestResponseDto>();
        }
    }

    // 8. Hủy yêu cầu trả hàng (chỉ khi còn pending)
    public async Task<bool> CancelReturnRequestAsync(string userId, string returnId)
    {
        try
        {
            var returnRequest = await _context.ReturnRequests
                .Include(r => r.Order)
                .FirstOrDefaultAsync(r => r.ReturnId == returnId && r.UserId == userId);

            if (returnRequest == null || returnRequest.Status != "pending")
                return false;

            // Lưu trạng thái cũ để gửi notification
            var oldStatus = returnRequest.Order?.Status ?? "return_requested";
            var newStatus = "completed";

            // Khôi phục trạng thái đơn hàng về completed
            if (returnRequest.Order != null)
            {
                returnRequest.Order.Status = newStatus;
            }

            // Xóa ảnh nếu có
            if (!string.IsNullOrEmpty(returnRequest.ImageUrl))
            {
                await _fileUploadService.DeleteImageAsync(returnRequest.ImageUrl);
            }

            _context.ReturnRequests.Remove(returnRequest);
            await _context.SaveChangesAsync();

            // Gửi notification realtime cho user
            if (returnRequest.Order != null)
            {
                await _realTimeService.NotifyOrderStatusChangedAsync(
                    orderId: returnRequest.Order.OrderId,
                    userId: userId,
                    oldStatus: oldStatus,
                    newStatus: newStatus,
                    orderCode: returnRequest.Order.OrderId
                );
            }

            _logger.LogInformation($"Return request {returnId} cancelled by user {userId}");

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi hủy yêu cầu trả hàng");
            return false;
        }
    }

    // Helper: Tạo mã returnId
    private string GenerateReturnId()
    {
        var random = new Random();
        var number = random.Next(100000, 999999).ToString();
        return $"RT{number}";
    }

    // Helper: Map entity -> DTO
    private ReturnRequestResponseDto MapToResponseDto(ReturnRequest request)
    {
        string statusText = request.Status switch
        {
            "pending" => "Chờ xử lý",
            "approved" => "Đã duyệt - Chờ gửi hàng trả",
            "rejected" => "Từ chối",
            "completed" => "Hoàn tất",
            _ => request.Status
        };

        return new ReturnRequestResponseDto
        {
            ReturnId = request.ReturnId,
            OrderId = request.OrderId,
            UserId = request.UserId,
            Reason = request.Reason,
            Description = request.Description,
            ImageUrl = request.ImageUrl,
            Status = request.Status,
            RefundAmount = request.RefundAmount,
            CreatedAt = request.CreatedAt,
            ApprovedAt = request.ApprovedAt,
            CompletedAt = request.CompletedAt,
            RejectedAt = request.RejectedAt,
            RejectReason = request.RejectReason,
            StatusText = statusText
        };
    }

    // 9. Lấy ReturnRequest theo orderId
    public async Task<ReturnRequest?> GetReturnByOrderIdAsync(string orderId, string userId, string? role)
    {
        try
        {
            var returnRequest = await _context.ReturnRequests
                .FirstOrDefaultAsync(r => r.OrderId == orderId);

            if (returnRequest == null) return null;

            // Kiểm tra quyền: user chỉ xem của mình, admin xem tất cả
            if (role != "admin" && returnRequest.UserId != userId)
                return null;

            return returnRequest;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy returnId theo orderId");
            return null;
        }
    }
}
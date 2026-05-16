using fruit_api.DTOs;
using fruit_api.Models;

namespace fruit_api.Services.Interfaces;

public interface IReturnService
{
    // Kiểm tra đơn hàng có được trả không
    Task<bool> CanReturnOrderAsync(string userId, string orderId);

    // Tạo yêu cầu trả hàng
    Task<ReturnRequestResponseDto?> CreateReturnRequestAsync(string userId, CreateReturnRequestDto dto);

    // Admin xử lý yêu cầu (duyệt/từ chối)
    Task<ReturnRequestResponseDto?> ProcessReturnRequestAsync(string adminId, ProcessReturnRequestDto dto);

    // Admin xác nhận đã nhận lại hàng
    Task<ReturnRequestResponseDto?> CompleteReturnAsync(string returnId);

    // Lấy chi tiết yêu cầu trả hàng
    Task<ReturnRequestResponseDto?> GetReturnRequestByIdAsync(string returnId, string userId, string? role);

    // Lấy danh sách yêu cầu của user hiện tại
    Task<List<ReturnRequestResponseDto>> GetUserReturnRequestsAsync(string userId);

    // Admin lấy tất cả yêu cầu trả hàng
    Task<List<ReturnRequestResponseDto>> GetAllReturnRequestsAsync(string? status = null);

    // Hủy yêu cầu trả hàng (khi còn pending)
    Task<bool> CancelReturnRequestAsync(string userId, string returnId);
    Task<ReturnRequest?> GetReturnByOrderIdAsync(string orderId, string userId, string? role);
}
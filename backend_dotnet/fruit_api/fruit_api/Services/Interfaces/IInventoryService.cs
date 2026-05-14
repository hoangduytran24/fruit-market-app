using fruit_api.DTOs.Inventory;

namespace fruit_api.Services.Interfaces;

public interface IInventoryService
{
    // Nhập hàng mới
    Task<InventoryDetailDto> CreateInventoryAsync(CreateInventoryDto createDto);

    // Lấy danh sách lô hàng (cho admin xem)
    Task<IEnumerable<InventoryListDto>> GetAllInventoriesAsync();

    // Lấy chi tiết 1 lô hàng
    Task<InventoryDetailDto?> GetInventoryByIdAsync(string inventoryId);

    // Cập nhật lô hàng (sửa số lượng, hạn sử dụng)
    Task<InventoryDetailDto> UpdateInventoryAsync(string inventoryId, UpdateInventoryDto updateDto);

    // Xóa lô hàng (nếu nhập sai)
    Task<bool> DeleteInventoryAsync(string inventoryId);
    Task<IEnumerable<ExpiryCheckDto>> GetExpiringInventoriesAsync(int daysThreshold = 7);
    Task<IEnumerable<ExpiryCheckDto>> GetExpiredInventoriesAsync();
}
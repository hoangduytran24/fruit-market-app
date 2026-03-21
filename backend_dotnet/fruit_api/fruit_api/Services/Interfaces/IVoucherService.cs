using fruit_api.DTOs.Voucher;

namespace fruit_api.Services.Interfaces;

public interface IVoucherService
{
    // ADMIN APIs
    Task<IEnumerable<VoucherDto>> GetAllVouchersAsync();
    Task<VoucherDto?> GetVoucherByIdAsync(string id);
    Task<VoucherDto> CreateVoucherAsync(CreateVoucherDto createDto);
    Task<VoucherDto> UpdateVoucherAsync(string id, UpdateVoucherDto updateDto);
    Task<bool> DeleteVoucherAsync(string id);
    Task<bool> ToggleVoucherStatusAsync(string id);

    // USER APIs
    Task<IEnumerable<VoucherPublicDto>> GetAvailableVouchersAsync();
    Task<VoucherResultDto> ApplyVoucherAsync(ApplyVoucherDto applyDto);

    // USER VOUCHER APIs (lưu voucher)
    Task<bool> SaveVoucherForUserAsync(string userId, string voucherCode);
    Task<IEnumerable<UserVoucherDto>> GetUserSavedVouchersAsync(string userId);
    Task<bool> UseSavedVoucherAsync(string userId, string userVoucherId);
}
using fruit_api.DTOs.Supplier;

namespace fruit_api.Services.Interfaces;

public interface ISupplierService
{
    Task<IEnumerable<SupplierDto>> GetAllSuppliersAsync();
    Task<SupplierDto?> GetSupplierByIdAsync(string id);
    Task<SupplierDto> CreateSupplierAsync(CreateSupplierDto createDto);
    Task<SupplierDto> UpdateSupplierAsync(string id, UpdateSupplierDto updateDto);
    Task<bool> DeleteSupplierAsync(string id);
}
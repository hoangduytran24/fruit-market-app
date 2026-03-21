using Microsoft.EntityFrameworkCore;
using fruit_api.Data;
using fruit_api.DTOs.Supplier;
using fruit_api.Models;
using fruit_api.Services.Interfaces;

namespace fruit_api.Services;

public class SupplierService : ISupplierService
{
    private readonly ApplicationDbContext _context;

    public SupplierService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<SupplierDto>> GetAllSuppliersAsync()
    {
        return await _context.Suppliers
            .Select(s => new SupplierDto
            {
                SupplierId = s.SupplierId,
                SupplierName = s.SupplierName,
                Phone = s.Phone,
                Address = s.Address,
                Status = s.Status,
                CreatedAt = s.CreatedAt,
                ProductCount = s.Products != null ? s.Products.Count(p => p.IsActive) : 0
            })
            .ToListAsync();
    }

    public async Task<SupplierDto?> GetSupplierByIdAsync(string id)
    {
        var supplier = await _context.Suppliers
            .Include(s => s.Products!.Where(p => p.IsActive))
            .FirstOrDefaultAsync(s => s.SupplierId == id);

        if (supplier == null)
            return null;

        return new SupplierDto
        {
            SupplierId = supplier.SupplierId,
            SupplierName = supplier.SupplierName,
            Phone = supplier.Phone,
            Address = supplier.Address,
            Status = supplier.Status,
            CreatedAt = supplier.CreatedAt,
            ProductCount = supplier.Products?.Count ?? 0
        };
    }

    public async Task<SupplierDto> CreateSupplierAsync(CreateSupplierDto createDto)
    {
        var supplier = new Supplier
        {
            SupplierName = createDto.SupplierName,
            Phone = createDto.Phone,
            Address = createDto.Address,
            Status = "active"
        };

        _context.Suppliers.Add(supplier);
        await _context.SaveChangesAsync();

        return new SupplierDto
        {
            SupplierId = supplier.SupplierId,
            SupplierName = supplier.SupplierName,
            Phone = supplier.Phone,
            Address = supplier.Address,
            Status = supplier.Status,
            CreatedAt = supplier.CreatedAt,
            ProductCount = 0
        };
    }

    public async Task<SupplierDto> UpdateSupplierAsync(string id, UpdateSupplierDto updateDto)
    {
        var supplier = await _context.Suppliers.FindAsync(id);
        if (supplier == null)
            throw new Exception("Supplier not found");

        supplier.SupplierName = updateDto.SupplierName;
        supplier.Phone = updateDto.Phone;
        supplier.Address = updateDto.Address;
        supplier.Status = updateDto.Status;

        await _context.SaveChangesAsync();

        return new SupplierDto
        {
            SupplierId = supplier.SupplierId,
            SupplierName = supplier.SupplierName,
            Phone = supplier.Phone,
            Address = supplier.Address,
            Status = supplier.Status,
            CreatedAt = supplier.CreatedAt,
            ProductCount = await _context.Products.CountAsync(p => p.SupplierId == id && p.IsActive)
        };
    }

    public async Task<bool> DeleteSupplierAsync(string id)
    {
        var supplier = await _context.Suppliers
            .Include(s => s.Products)
            .FirstOrDefaultAsync(s => s.SupplierId == id);

        if (supplier == null)
            throw new Exception("Supplier not found");

        // Check if supplier has products
        if (supplier.Products != null && supplier.Products.Any())
            throw new Exception("Cannot delete supplier with existing products");

        _context.Suppliers.Remove(supplier);
        await _context.SaveChangesAsync();

        return true;
    }
}
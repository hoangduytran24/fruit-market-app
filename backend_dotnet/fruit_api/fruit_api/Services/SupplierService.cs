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
                Email = s.Email,
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
            Email = supplier.Email,
            Address = supplier.Address,
            Status = supplier.Status,
            CreatedAt = supplier.CreatedAt,
            ProductCount = supplier.Products?.Count ?? 0
        };
    }

    public async Task<SupplierDto> CreateSupplierAsync(CreateSupplierDto createDto)
    {
        try
        {
            // Kiểm tra tên nhà cung cấp đã tồn tại chưa
            var existing = await _context.Suppliers
                .FirstOrDefaultAsync(s => s.SupplierName == createDto.SupplierName);

            if (existing != null)
                throw new Exception($"Nhà cung cấp '{createDto.SupplierName}' đã tồn tại");

            // Kiểm tra email đã tồn tại chưa (nếu có)
            if (!string.IsNullOrEmpty(createDto.Email))
            {
                var existingEmail = await _context.Suppliers
                    .FirstOrDefaultAsync(s => s.Email == createDto.Email);

                if (existingEmail != null)
                    throw new Exception($"Email '{createDto.Email}' đã được sử dụng");
            }

            // Tạo ID mới
            string supplierId = await GenerateSupplierId();

            var supplier = new Supplier
            {
                SupplierId = supplierId,
                SupplierName = createDto.SupplierName.Trim(),
                Phone = createDto.Phone,
                Email = createDto.Email,
                Address = createDto.Address,
                Status = "active",
                CreatedAt = DateTime.UtcNow
            };

            _context.Suppliers.Add(supplier);
            await _context.SaveChangesAsync();

            return new SupplierDto
            {
                SupplierId = supplier.SupplierId,
                SupplierName = supplier.SupplierName,
                Phone = supplier.Phone,
                Email = supplier.Email,
                Address = supplier.Address,
                Status = supplier.Status,
                CreatedAt = supplier.CreatedAt,
                ProductCount = 0
            };
        }
        catch (DbUpdateException dbEx)
        {
            var innerMessage = dbEx.InnerException?.Message ?? dbEx.Message;
            throw new Exception($"Lỗi database: {innerMessage}");
        }
        catch (Exception ex)
        {
            throw;
        }
    }

    public async Task<SupplierDto> UpdateSupplierAsync(string id, UpdateSupplierDto updateDto)
    {
        try
        {
            var supplier = await _context.Suppliers.FindAsync(id);
            if (supplier == null)
                throw new Exception("Không tìm thấy nhà cung cấp");

            // Kiểm tra tên đã tồn tại (trừ chính nó)
            var existing = await _context.Suppliers
                .FirstOrDefaultAsync(s => s.SupplierName == updateDto.SupplierName && s.SupplierId != id);

            if (existing != null)
                throw new Exception($"Nhà cung cấp '{updateDto.SupplierName}' đã tồn tại");

            // Kiểm tra email đã tồn tại (trừ chính nó)
            if (!string.IsNullOrEmpty(updateDto.Email))
            {
                var existingEmail = await _context.Suppliers
                    .FirstOrDefaultAsync(s => s.Email == updateDto.Email && s.SupplierId != id);

                if (existingEmail != null)
                    throw new Exception($"Email '{updateDto.Email}' đã được sử dụng");
            }

            supplier.SupplierName = updateDto.SupplierName.Trim();
            supplier.Phone = updateDto.Phone;
            supplier.Email = updateDto.Email;
            supplier.Address = updateDto.Address;
            supplier.Status = updateDto.Status;

            await _context.SaveChangesAsync();

            return new SupplierDto
            {
                SupplierId = supplier.SupplierId,
                SupplierName = supplier.SupplierName,
                Phone = supplier.Phone,
                Email = supplier.Email,
                Address = supplier.Address,
                Status = supplier.Status,
                CreatedAt = supplier.CreatedAt,
                ProductCount = await _context.Products.CountAsync(p => p.SupplierId == id && p.IsActive)
            };
        }
        catch (DbUpdateException dbEx)
        {
            var innerMessage = dbEx.InnerException?.Message ?? dbEx.Message;
            throw new Exception($"Lỗi database: {innerMessage}");
        }
        catch (Exception ex)
        {
            throw;
        }
    }

    public async Task<bool> DeleteSupplierAsync(string id)
    {
        var supplier = await _context.Suppliers
            .Include(s => s.Products)
            .FirstOrDefaultAsync(s => s.SupplierId == id);

        if (supplier == null)
            throw new Exception("Không tìm thấy nhà cung cấp");

        // Kiểm tra xem nhà cung cấp có sản phẩm không
        if (supplier.Products != null && supplier.Products.Any())
            throw new Exception("Không thể xóa nhà cung cấp vì đang có sản phẩm liên kết");

        _context.Suppliers.Remove(supplier);
        await _context.SaveChangesAsync();

        return true;
    }

    // Helper để tạo SupplierId duy nhất
    private async Task<string> GenerateSupplierId()
    {
        var random = new Random();
        string supplierId;
        bool exists;
        int attempt = 0;
        const int maxAttempts = 10;

        do
        {
            var randomNumber = random.Next(100000, 999999).ToString();
            supplierId = "SU" + randomNumber;
            exists = await _context.Suppliers.AnyAsync(s => s.SupplierId == supplierId);
            attempt++;

            if (attempt >= maxAttempts)
                throw new Exception("Không thể tạo ID nhà cung cấp duy nhất");

        } while (exists);

        return supplierId;
    }
}
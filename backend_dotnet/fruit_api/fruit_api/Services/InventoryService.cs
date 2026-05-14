using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using fruit_api.Data;
using fruit_api.DTOs.Inventory;
using fruit_api.Models;
using fruit_api.Services.Interfaces;

namespace fruit_api.Services;

public class InventoryService : IInventoryService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<InventoryService> _logger;
    private static readonly Random _idRandom = new();

    public InventoryService(
        ApplicationDbContext context,
        ILogger<InventoryService> logger)
    {
        _context = context;
        _logger = logger;
    }

    private static string GenerateId(string prefix)
    {
        var ts = DateTime.UtcNow.ToString("yyMMddHHmmss");
        var rnd = _idRandom.Next(100, 1000);
        return $"{prefix}{ts}{rnd}";
    }

    private static string GetStatusText(string status, DateTime expiryDate)
    {
        if (expiryDate < DateTime.Today)
            return "Hết hạn";

        return status switch
        {
            "in_stock" => "Còn hàng",
            "sold_out" => "Đã bán hết",
            _ => "Không xác định"
        };
    }

    private static int GetDaysToExpiry(DateTime expiryDate)
    {
        var days = (expiryDate - DateTime.Today).Days;
        return days > 0 ? days : 0;
    }

    public async Task<InventoryDetailDto> CreateInventoryAsync(CreateInventoryDto createDto)
    {
        try
        {
            // Kiểm tra sản phẩm tồn tại
            var product = await _context.Products.FindAsync(createDto.ProductId);
            if (product == null)
                throw new Exception($"Sản phẩm với ID {createDto.ProductId} không tồn tại trong hệ thống");

            var existingBatch = await _context.Inventories
                .FirstOrDefaultAsync(i => i.BatchCode == createDto.BatchCode);

            if (existingBatch != null)
                throw new Exception($"Mã lô hàng '{createDto.BatchCode}' đã tồn tại trong hệ thống. Vui lòng nhập mã lô khác.");

            // Kiểm tra ngày hết hạn
            if (createDto.ExpiryDate <= DateTime.Today)
                throw new Exception("Ngày hết hạn phải sau ngày hiện tại");

            if (createDto.ManufactureDate.HasValue && createDto.ExpiryDate <= createDto.ManufactureDate.Value)
                throw new Exception("Ngày hết hạn phải sau ngày sản xuất");

            // Tạo ID mới
            string inventoryId;
            int attempt = 0;
            do
            {
                inventoryId = GenerateId("INV");
                attempt++;
                if (attempt > 10)
                    throw new Exception("Could not generate unique inventory ID");
            } while (await _context.Inventories.AnyAsync(i => i.InventoryId == inventoryId));

            // Tạo lô hàng mới
            var inventory = new Inventory
            {
                InventoryId = inventoryId,
                ProductId = createDto.ProductId,
                BatchCode = createDto.BatchCode,
                Quantity = createDto.Quantity,
                ManufactureDate = createDto.ManufactureDate,
                ExpiryDate = createDto.ExpiryDate,
                ImportPrice = createDto.ImportPrice,
                ImportDate = DateTime.Now,
                Status = "in_stock",
                CreatedAt = DateTime.Now
            };

            _context.Inventories.Add(inventory);

            // Cập nhật tổng số lượng trong bảng Products
            product.StockQuantity += createDto.Quantity;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Inventory created successfully: {InventoryId} - Product: {ProductName} - Quantity: {Quantity}",
                inventory.InventoryId, product.ProductName, createDto.Quantity);

            return await GetInventoryByIdAsync(inventory.InventoryId) ?? throw new Exception("Failed to create inventory");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating inventory for product: {ProductId}", createDto.ProductId);
            throw;
        }
    }

    public async Task<IEnumerable<InventoryListDto>> GetAllInventoriesAsync()
    {
        try
        {
            var inventories = await _context.Inventories
                .Include(i => i.Product)
                .OrderByDescending(i => i.ImportDate)
                .Select(i => new InventoryListDto
                {
                    InventoryId = i.InventoryId,
                    ProductId = i.ProductId,
                    ProductName = i.Product != null ? i.Product.ProductName : string.Empty,
                    ProductImage = i.Product != null ? i.Product.ImageUrl : string.Empty,
                    BatchCode = i.BatchCode,
                    Quantity = i.Quantity,
                    ManufactureDate = i.ManufactureDate,
                    ExpiryDate = i.ExpiryDate,
                    ImportPrice = i.ImportPrice,
                    ImportDate = i.ImportDate,
                    Status = i.Status,
                    StatusText = GetStatusText(i.Status, i.ExpiryDate),
                    IsExpired = i.ExpiryDate < DateTime.Today,
                    DaysToExpiry = GetDaysToExpiry(i.ExpiryDate)
                })
                .ToListAsync();

            return inventories;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all inventories");
            throw;
        }
    }

    public async Task<IEnumerable<InventoryListDto>> GetInventoriesByProductIdAsync(string productId)
    {
        try
        {
            var inventories = await _context.Inventories
                .Include(i => i.Product)
                .Where(i => i.ProductId == productId)
                .OrderBy(i => i.ExpiryDate)
                .Select(i => new InventoryListDto
                {
                    InventoryId = i.InventoryId,
                    ProductId = i.ProductId,
                    ProductName = i.Product != null ? i.Product.ProductName : string.Empty,
                    ProductImage = i.Product != null ? i.Product.ImageUrl : string.Empty,
                    BatchCode = i.BatchCode,
                    Quantity = i.Quantity,
                    ManufactureDate = i.ManufactureDate,
                    ExpiryDate = i.ExpiryDate,
                    ImportPrice = i.ImportPrice,
                    ImportDate = i.ImportDate,
                    Status = i.Status,
                    StatusText = GetStatusText(i.Status, i.ExpiryDate),
                    IsExpired = i.ExpiryDate < DateTime.Today,
                    DaysToExpiry = GetDaysToExpiry(i.ExpiryDate)
                })
                .ToListAsync();

            return inventories;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting inventories by product: {ProductId}", productId);
            throw;
        }
    }

    public async Task<InventoryDetailDto?> GetInventoryByIdAsync(string inventoryId)
    {
        try
        {
            var inventory = await _context.Inventories
                .Include(i => i.Product)
                    .ThenInclude(p => p!.Category)
                .Include(i => i.Product)
                    .ThenInclude(p => p!.Supplier)
                .FirstOrDefaultAsync(i => i.InventoryId == inventoryId);

            if (inventory == null)
                return null;

            return new InventoryDetailDto
            {
                InventoryId = inventory.InventoryId,
                ProductId = inventory.ProductId,
                ProductName = inventory.Product?.ProductName ?? string.Empty,
                ProductImage = inventory.Product?.ImageUrl ?? string.Empty,
                CategoryName = inventory.Product?.Category?.CategoryName ?? string.Empty,
                SupplierName = inventory.Product?.Supplier?.SupplierName ?? string.Empty,
                BatchCode = inventory.BatchCode,
                Quantity = inventory.Quantity,
                ManufactureDate = inventory.ManufactureDate,
                ExpiryDate = inventory.ExpiryDate,
                ImportPrice = inventory.ImportPrice,
                ImportDate = inventory.ImportDate,
                Status = inventory.Status,
                StatusText = GetStatusText(inventory.Status, inventory.ExpiryDate),
                IsExpired = inventory.ExpiryDate < DateTime.Today,
                DaysToExpiry = GetDaysToExpiry(inventory.ExpiryDate),
                CreatedAt = inventory.CreatedAt
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting inventory by ID: {InventoryId}", inventoryId);
            throw;
        }
    }

    public async Task<InventoryDetailDto> UpdateInventoryAsync(string inventoryId, UpdateInventoryDto updateDto)
    {
        try
        {
            var inventory = await _context.Inventories
                .Include(i => i.Product)
                .FirstOrDefaultAsync(i => i.InventoryId == inventoryId);

            if (inventory == null)
                throw new Exception($"Inventory with ID {inventoryId} not found");

            var oldQuantity = inventory.Quantity;

            if (updateDto.Quantity.HasValue)
            {
                if (updateDto.Quantity.Value < 0)
                    throw new Exception("Quantity cannot be negative");

                var quantityDiff = updateDto.Quantity.Value - inventory.Quantity;
                inventory.Quantity = updateDto.Quantity.Value;

                // Cập nhật tồn kho sản phẩm
                if (inventory.Product != null)
                {
                    inventory.Product.StockQuantity += quantityDiff;
                }
            }

            if (updateDto.ManufactureDate.HasValue)
                inventory.ManufactureDate = updateDto.ManufactureDate;

            if (updateDto.ExpiryDate.HasValue)
            {
                if (updateDto.ExpiryDate.Value <= DateTime.Today)
                    throw new Exception("Ngày hết hạn phải sau ngày hiện tại");
                inventory.ExpiryDate = updateDto.ExpiryDate.Value;
            }

            if (updateDto.ImportPrice.HasValue)
                inventory.ImportPrice = updateDto.ImportPrice;

            if (!string.IsNullOrEmpty(updateDto.Status))
            {
                var validStatuses = new[] { "in_stock", "expired", "sold_out" };
                if (!validStatuses.Contains(updateDto.Status))
                    throw new Exception("Invalid status value");
                inventory.Status = updateDto.Status;
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("Inventory updated successfully: {InventoryId}", inventoryId);

            return await GetInventoryByIdAsync(inventoryId) ?? throw new Exception("Failed to update inventory");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating inventory: {InventoryId}", inventoryId);
            throw;
        }
    }

    public async Task<bool> DeleteInventoryAsync(string inventoryId)
    {
        try
        {
            var inventory = await _context.Inventories
                .Include(i => i.Product)
                .FirstOrDefaultAsync(i => i.InventoryId == inventoryId);

            if (inventory == null)
                throw new Exception($"Inventory with ID {inventoryId} not found");

            // Trả lại số lượng cho sản phẩm
            if (inventory.Product != null && inventory.Quantity > 0)
            {
                inventory.Product.StockQuantity -= inventory.Quantity;
            }

            _context.Inventories.Remove(inventory);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Inventory deleted successfully: {InventoryId}", inventoryId);

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting inventory: {InventoryId}", inventoryId);
            throw;
        }
    }

    public async Task<int> GetTotalStockByProductIdAsync(string productId)
    {
        try
        {
            var totalStock = await _context.Inventories
                .Where(i => i.ProductId == productId
                    && i.Status == "in_stock"
                    && i.ExpiryDate > DateTime.Today)
                .SumAsync(i => i.Quantity);

            return totalStock;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting total stock for product: {ProductId}", productId);
            throw;
        }
    }

    public async Task<IEnumerable<ExpiryCheckDto>> GetExpiringInventoriesAsync(int daysThreshold = 7)
    {
        try
        {
            var expiryDateThreshold = DateTime.Today.AddDays(daysThreshold);

            var expiringInventories = await _context.Inventories
                .Include(i => i.Product)
                .Where(i => i.Status == "in_stock"
                    && i.ExpiryDate <= expiryDateThreshold
                    && i.ExpiryDate > DateTime.Today
                    && i.Quantity > 0)
                .OrderBy(i => i.ExpiryDate)
                .Select(i => new ExpiryCheckDto
                {
                    InventoryId = i.InventoryId,
                    ProductName = i.Product != null ? i.Product.ProductName : string.Empty,
                    BatchCode = i.BatchCode,
                    Quantity = i.Quantity,
                    ExpiryDate = i.ExpiryDate,
                    DaysToExpiry = GetDaysToExpiry(i.ExpiryDate),
                    IsExpired = false,
                    Status = i.Status,
                    ImportPrice = i.ImportPrice
                })
                .ToListAsync();

            return expiringInventories;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting expiring inventories");
            throw;
        }
    }

    public async Task<IEnumerable<ExpiryCheckDto>> GetExpiredInventoriesAsync()
    {
        try
        {
            var expiredInventories = await _context.Inventories
                .Include(i => i.Product)
                .Where(i => i.ExpiryDate < DateTime.Today && i.Quantity > 0)
                .OrderBy(i => i.ExpiryDate)
                .Select(i => new ExpiryCheckDto
                {
                    InventoryId = i.InventoryId,
                    ProductName = i.Product != null ? i.Product.ProductName : string.Empty,
                    BatchCode = i.BatchCode,
                    Quantity = i.Quantity,
                    ExpiryDate = i.ExpiryDate,
                    DaysToExpiry = 0,
                    IsExpired = true,
                    Status = i.Status,
                    ImportPrice = i.ImportPrice
                })
                .ToListAsync();

            return expiredInventories;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting expired inventories");
            throw;
        }
    }

    public async Task<int> AutoUpdateExpiredStatusAsync()
    {
        try
        {
            var expiredInventories = await _context.Inventories
                .Where(i => i.Status == "in_stock" && i.ExpiryDate < DateTime.Today && i.Quantity > 0)
                .ToListAsync();

            foreach (var inventory in expiredInventories)
            {
                inventory.Status = "expired";
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("Auto-updated {Count} expired inventories", expiredInventories.Count);

            return expiredInventories.Count;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error auto-updating expired status");
            throw;
        }
    }
}
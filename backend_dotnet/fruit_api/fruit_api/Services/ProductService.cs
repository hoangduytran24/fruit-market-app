using System;
using System.IO;
using System.Linq;
using fruit_api.Data;
using fruit_api.DTOs.Product;
using fruit_api.DTOs.Review;
using fruit_api.Models;
using fruit_api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace fruit_api.Services;

public class ProductService : IProductService
{
    private readonly ApplicationDbContext _context;
    private readonly IWebHostEnvironment _environment;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ProductService> _logger;
    private static readonly Random _idRandom = new();

    public ProductService(
        ApplicationDbContext context,
        IWebHostEnvironment environment,
        IHttpContextAccessor httpContextAccessor,
        IConfiguration configuration,
        ILogger<ProductService> logger)
    {
        _context = context;
        _environment = environment;
        _httpContextAccessor = httpContextAccessor;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<ProductResponseDto> GetAllProductsAsync(ProductSearchDto searchDto)
    {
        try
        {
            var query = _context.Products
                .Include(p => p.Category)
                .Include(p => p.Supplier)
                .Include(p => p.Reviews)
                .Include(p => p.Inventories)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(searchDto.Keyword))
            {
                query = query.Where(p =>
                    p.ProductName.Contains(searchDto.Keyword) ||
                    (p.Description != null && p.Description.Contains(searchDto.Keyword)));
            }

            if (!string.IsNullOrWhiteSpace(searchDto.CategoryId))
            {
                query = query.Where(p => p.CategoryId == searchDto.CategoryId);
            }

            if (searchDto.MinPrice.HasValue)
            {
                query = query.Where(p => p.Price >= searchDto.MinPrice.Value);
            }

            if (searchDto.MaxPrice.HasValue)
            {
                query = query.Where(p => p.Price <= searchDto.MaxPrice.Value);
            }

            if (searchDto.InStock.HasValue && searchDto.InStock.Value)
            {
                query = query.Where(p => p.StockQuantity > 0);
            }

            var totalCount = await query.CountAsync();

            var products = await query
                .OrderByDescending(p => p.CreatedAt)
                .Skip((searchDto.Page - 1) * searchDto.PageSize)
                .Take(searchDto.PageSize)
                .ToListAsync();

            var items = new List<ProductListDto>();
            foreach (var p in products)
            {
                var nearestBatch = p.Inventories?
                    .Where(i => i.Status == "in_stock" && i.Quantity > 0 && i.ExpiryDate > DateTime.Today)
                    .OrderBy(i => i.ExpiryDate)
                    .FirstOrDefault();

                items.Add(new ProductListDto
                {
                    ProductId = p.ProductId,
                    ProductName = p.ProductName,
                    CategoryId = p.CategoryId,
                    CategoryName = p.Category?.CategoryName ?? string.Empty,
                    SupplierId = p.SupplierId,
                    SupplierName = p.Supplier?.SupplierName ?? string.Empty,
                    SupplierAddress = p.Supplier?.Address ?? string.Empty,
                    Unit = p.Unit,
                    Price = p.Price,
                    StockQuantity = p.StockQuantity,  // SỬA: Dùng stock từ Products
                    ImageUrl = p.ImageUrl,
                    Description = p.Description,
                    IsActive = p.IsActive,
                    Origin = p.Origin,
                    AverageRating = p.Reviews != null && p.Reviews.Any()
                        ? Math.Round(p.Reviews.Average(r => r.Rating), 1)
                        : 0,
                    ReviewCount = p.Reviews?.Count ?? 0,
                    ManufactureDate = nearestBatch?.ManufactureDate,
                    ExpiryDate = nearestBatch?.ExpiryDate,
                    DaysToExpiry = nearestBatch != null
                        ? (nearestBatch.ExpiryDate - DateTime.Today).Days
                        : 0,
                    IsExpired = nearestBatch == null
                });
            }

            var totalPages = (int)Math.Ceiling(totalCount / (double)searchDto.PageSize);

            return new ProductResponseDto
            {
                Items = items,
                TotalCount = totalCount,
                Page = searchDto.Page,
                PageSize = searchDto.PageSize,
                TotalPages = totalPages
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting products");
            throw new Exception($"Error getting products: {ex.Message}", ex);
        }
    }

    public async Task<ProductDetailDto?> GetProductByIdAsync(string id)
    {
        try
        {
            var product = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Supplier)
                .Include(p => p.Reviews!)
                    .ThenInclude(r => r.User)
                .Include(p => p.Inventories)
                .FirstOrDefaultAsync(p => p.ProductId == id);

            if (product == null)
                return null;

            var nearestBatch = product.Inventories?
                .Where(i => i.Status == "in_stock" && i.Quantity > 0 && i.ExpiryDate > DateTime.Today)
                .OrderBy(i => i.ExpiryDate)
                .FirstOrDefault();

            var productDto = new ProductDetailDto
            {
                ProductId = product.ProductId,
                ProductName = product.ProductName,
                CategoryId = product.CategoryId,
                CategoryName = product.Category?.CategoryName ?? string.Empty,
                SupplierId = product.SupplierId,
                SupplierName = product.Supplier?.SupplierName ?? string.Empty,
                Unit = product.Unit,
                Price = product.Price,
                StockQuantity = product.StockQuantity,  // SỬA: Dùng stock từ Products
                Description = product.Description,
                ImageUrl = product.ImageUrl,
                IsActive = product.IsActive,
                CreatedAt = product.CreatedAt,
                Origin = product.Origin,
                ManufactureDate = nearestBatch?.ManufactureDate,
                ExpiryDate = nearestBatch?.ExpiryDate,
                Reviews = product.Reviews != null
                    ? product.Reviews.Select(r => new ReviewDto
                    {
                        ReviewId = r.ReviewId,
                        UserId = r.UserId,
                        UserName = r.User?.FullName ?? string.Empty,
                        Rating = r.Rating,
                        Comment = r.Comment,
                        CreatedAt = r.CreatedAt
                    }).OrderByDescending(r => r.CreatedAt).ToList()
                    : new List<ReviewDto>(),
                AverageRating = product.Reviews != null && product.Reviews.Any()
                    ? Math.Round(product.Reviews.Average(r => r.Rating), 1)
                    : 0,
                ReviewCount = product.Reviews?.Count ?? 0
            };

            return productDto;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting product by ID: {ProductId}", id);
            throw;
        }
    }

    public async Task<IEnumerable<ProductListDto>> SearchProductsByNameAsync(string keyword)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(keyword))
                return new List<ProductListDto>();

            var products = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Reviews)
                .Include(p => p.Inventories)
                .Where(p => p.ProductName.Contains(keyword) && p.IsActive)
                .OrderBy(p => p.ProductName)
                .Take(20)
                .ToListAsync();

            var result = new List<ProductListDto>();
            foreach (var p in products)
            {
                var nearestBatch = p.Inventories?
                    .Where(i => i.Status == "in_stock" && i.Quantity > 0 && i.ExpiryDate > DateTime.Today)
                    .OrderBy(i => i.ExpiryDate)
                    .FirstOrDefault();

                result.Add(new ProductListDto
                {
                    ProductId = p.ProductId,
                    ProductName = p.ProductName,
                    CategoryName = p.Category?.CategoryName ?? string.Empty,
                    Unit = p.Unit,
                    Price = p.Price,
                    StockQuantity = p.StockQuantity,  // SỬA: Dùng stock từ Products
                    ImageUrl = p.ImageUrl,
                    Origin = p.Origin,
                    AverageRating = p.Reviews != null && p.Reviews.Any()
                        ? Math.Round(p.Reviews.Average(r => r.Rating), 1)
                        : 0,
                    ReviewCount = p.Reviews?.Count ?? 0,
                    ManufactureDate = nearestBatch?.ManufactureDate,
                    ExpiryDate = nearestBatch?.ExpiryDate,
                    DaysToExpiry = nearestBatch != null
                        ? (nearestBatch.ExpiryDate - DateTime.Today).Days
                        : 0,
                    IsExpired = nearestBatch == null
                });
            }

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error searching products by name: {Keyword}", keyword);
            throw;
        }
    }

    public async Task<IEnumerable<ProductListDto>> GetProductsByCategoryAsync(string categoryId)
    {
        try
        {
            var products = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Reviews)
                .Include(p => p.Inventories)
                .Where(p => p.CategoryId == categoryId && p.IsActive)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();

            var result = new List<ProductListDto>();
            foreach (var p in products)
            {
                var nearestBatch = p.Inventories?
                    .Where(i => i.Status == "in_stock" && i.Quantity > 0 && i.ExpiryDate > DateTime.Today)
                    .OrderBy(i => i.ExpiryDate)
                    .FirstOrDefault();

                result.Add(new ProductListDto
                {
                    ProductId = p.ProductId,
                    ProductName = p.ProductName,
                    CategoryName = p.Category?.CategoryName ?? string.Empty,
                    Unit = p.Unit,
                    Price = p.Price,
                    StockQuantity = p.StockQuantity,  // SỬA: Dùng stock từ Products
                    ImageUrl = p.ImageUrl,
                    Origin = p.Origin,
                    AverageRating = p.Reviews != null && p.Reviews.Any()
                        ? Math.Round(p.Reviews.Average(r => r.Rating), 1)
                        : 0,
                    ReviewCount = p.Reviews?.Count ?? 0,
                    ManufactureDate = nearestBatch?.ManufactureDate,
                    ExpiryDate = nearestBatch?.ExpiryDate,
                    DaysToExpiry = nearestBatch != null
                        ? (nearestBatch.ExpiryDate - DateTime.Today).Days
                        : 0,
                    IsExpired = nearestBatch == null
                });
            }

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting products by category: {CategoryId}", categoryId);
            throw;
        }
    }

    public async Task<ProductDto> CreateProductAsync(CreateProductDto createDto)
    {
        try
        {
            string? savedImagePath = null;
            if (createDto.ImageFile != null)
            {
                savedImagePath = await SaveImageFileAsync(createDto.ImageFile, "products");
            }

            var category = await _context.Categories.FindAsync(createDto.CategoryId);
            if (category == null)
                throw new Exception($"Category with ID {createDto.CategoryId} not found");

            var supplier = await _context.Suppliers.FindAsync(createDto.SupplierId);
            if (supplier == null)
                throw new Exception($"Supplier with ID {createDto.SupplierId} not found");

            var existingProduct = await _context.Products
                .FirstOrDefaultAsync(p => p.ProductName.ToLower() == createDto.ProductName.ToLower());

            if (existingProduct != null)
                throw new Exception($"Product with name '{createDto.ProductName}' already exists");

            string productId;
            int attempt = 0;
            do
            {
                productId = GenerateId("PR");
                attempt++;
                if (attempt > 10)
                    throw new Exception("Could not generate unique product ID");
            } while (await _context.Products.AnyAsync(p => p.ProductId == productId));

            var product = new Product
            {
                ProductId = productId,
                CategoryId = createDto.CategoryId,
                SupplierId = createDto.SupplierId,
                ProductName = createDto.ProductName.Trim(),
                Unit = createDto.Unit,
                Price = createDto.Price,
                StockQuantity = 0,
                Description = createDto.Description,
                ImageUrl = savedImagePath,
                Origin = createDto.Origin,
                IsActive = true,
                CreatedAt = DateTime.Now
            };

            _context.Products.Add(product);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Product created successfully: {ProductId} - {ProductName}",
                product.ProductId, product.ProductName);

            return new ProductDto
            {
                ProductId = product.ProductId,
                ProductName = product.ProductName,
                CategoryId = product.CategoryId,
                CategoryName = category.CategoryName,
                SupplierId = product.SupplierId,
                SupplierName = supplier.SupplierName,
                Unit = product.Unit,
                Price = product.Price,
                StockQuantity = 0,
                Description = product.Description,
                ImageUrl = product.ImageUrl,
                IsActive = product.IsActive,
                CreatedAt = product.CreatedAt,
                Origin = product.Origin
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating product");
            throw;
        }
    }

    private static string GenerateId(string prefix)
    {
        var ts = DateTime.UtcNow.ToString("yyMMddHHmmss");
        var rnd = _idRandom.Next(100, 1000);
        return $"{prefix}{ts}{rnd}";
    }

    public async Task<ProductDto> UpdateProductAsync(string id, UpdateProductDto updateDto)
    {
        try
        {
            string? savedImagePath = null;
            if (updateDto.ImageFile != null)
            {
                savedImagePath = await SaveImageFileAsync(updateDto.ImageFile, "products");
            }

            var product = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Supplier)
                .FirstOrDefaultAsync(p => p.ProductId == id);

            if (product == null)
                throw new Exception($"Product with ID {id} not found");

            var category = await _context.Categories.FindAsync(updateDto.CategoryId);
            if (category == null)
                throw new Exception($"Category with ID {updateDto.CategoryId} not found");

            var supplier = await _context.Suppliers.FindAsync(updateDto.SupplierId);
            if (supplier == null)
                throw new Exception($"Supplier with ID {updateDto.SupplierId} not found");

            var existingProduct = await _context.Products
                .FirstOrDefaultAsync(p => p.ProductName.ToLower() == updateDto.ProductName.ToLower()
                    && p.ProductId != id);

            if (existingProduct != null)
                throw new Exception($"Product with name '{updateDto.ProductName}' already exists");

            product.CategoryId = updateDto.CategoryId;
            product.SupplierId = updateDto.SupplierId;
            product.ProductName = updateDto.ProductName.Trim();
            product.Unit = updateDto.Unit;
            product.Price = updateDto.Price;
            product.Description = updateDto.Description;
            product.Origin = updateDto.Origin;
            if (!string.IsNullOrEmpty(savedImagePath))
            {
                product.ImageUrl = savedImagePath;
            }
            product.IsActive = updateDto.IsActive;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Product updated successfully: {ProductId}", product.ProductId);

            return new ProductDto
            {
                ProductId = product.ProductId,
                ProductName = product.ProductName,
                CategoryId = product.CategoryId,
                CategoryName = category.CategoryName,
                SupplierId = product.SupplierId,
                SupplierName = supplier.SupplierName,
                Unit = product.Unit,
                Price = product.Price,
                StockQuantity = product.StockQuantity,  // SỬA: Dùng stock từ Products
                Description = product.Description,
                ImageUrl = product.ImageUrl,
                IsActive = product.IsActive,
                CreatedAt = product.CreatedAt,
                Origin = product.Origin
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating product: {ProductId}", id);
            throw;
        }
    }

    public async Task<bool> DeleteProductAsync(string id)
    {
        try
        {
            var product = await _context.Products
                .Include(p => p.OrderItems)
                .Include(p => p.CartItems)
                .FirstOrDefaultAsync(p => p.ProductId == id);

            if (product == null)
                throw new Exception($"Product with ID {id} not found");

            if (product.OrderItems != null && product.OrderItems.Any())
            {
                product.IsActive = false;
                _logger.LogInformation("Product soft deleted (has orders): {ProductId}", id);
            }
            else
            {
                if (product.CartItems != null && product.CartItems.Any())
                {
                    _context.CartItems.RemoveRange(product.CartItems);
                }
                _context.Products.Remove(product);
                _logger.LogInformation("Product hard deleted: {ProductId}", id);
            }

            await _context.SaveChangesAsync();
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting product: {ProductId}", id);
            throw;
        }
    }

    public async Task<bool> UpdateProductStatusAsync(string productId, bool isActive)
    {
        try
        {
            var product = await _context.Products.FindAsync(productId);

            if (product == null)
                throw new Exception($"Sản phẩm với ID {productId} không tồn tại");

            product.IsActive = isActive;

            await _context.SaveChangesAsync();

            _logger.LogInformation($"Product {productId} status updated to {isActive}");

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error updating product status: {productId}");
            throw;
        }
    }

    public async Task<bool> RestoreProductAsync(string id)
    {
        try
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null)
                throw new Exception($"Product with ID {id} not found");

            product.IsActive = true;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Product restored: {ProductId}", id);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error restoring product: {ProductId}", id);
            throw;
        }
    }

    public async Task<bool> UpdateStockAsync(string id, int quantity)
    {
        try
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null)
                throw new Exception($"Product with ID {id} not found");

            if (quantity < 0)
                throw new Exception("Quantity cannot be negative");

            product.StockQuantity = quantity;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Product stock updated: {ProductId} - New stock: {Quantity}", id, quantity);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating stock for product: {ProductId}", id);
            throw;
        }
    }

    public async Task<bool> IsInStockAsync(string id, int quantity = 1)
    {
        try
        {
            var product = await _context.Products.FindAsync(id);
            return product != null && product.IsActive && product.StockQuantity >= quantity;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking stock for product: {ProductId}", id);
            throw;
        }
    }

    // --- File helpers ---
    private string[] GetAllowedExtensions()
    {
        return _configuration.GetSection("FileSettings:AllowedExtensions").Get<string[]>()
            ?? new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
    }

    private bool IsImageFile(string fileName)
    {
        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        return GetAllowedExtensions().Contains(extension);
    }

    private bool IsValidImageSize(long fileSize, long maxSizeInMB = 5)
    {
        var maxSizeInBytes = maxSizeInMB * 1024 * 1024;
        return fileSize <= maxSizeInBytes;
    }

    private string GenerateUniqueFileName(string originalFileName)
    {
        var extension = Path.GetExtension(originalFileName);
        var fileNameWithoutExt = Path.GetFileNameWithoutExtension(originalFileName);
        var timestamp = DateTime.Now.ToString("yyyyMMddHHmmss");
        var guid = Guid.NewGuid().ToString("N").Substring(0, 8);

        var safeName = string.Join("_", fileNameWithoutExt.Split(Path.GetInvalidFileNameChars()));

        return $"{safeName}_{timestamp}_{guid}{extension}";
    }

    private string GetScaledFileName(string originalFileName, int size)
    {
        var ext = Path.GetExtension(originalFileName);
        var name = Path.GetFileNameWithoutExtension(originalFileName);
        return $"{name}_scaled_{size}{ext}";
    }

    private async Task CreateScaledImageAsync(string sourcePath, string destPath, int width)
    {
        try
        {
            using var image = await Image.LoadAsync(sourcePath);

            if (image.Width <= width)
            {
                File.Copy(sourcePath, destPath, overwrite: true);
                return;
            }

            var aspect = image.Height / (double)image.Width;
            var height = (int)Math.Round(width * aspect);

            image.Mutate(x => x.Resize(new ResizeOptions
            {
                Mode = ResizeMode.Max,
                Size = new Size(width, height)
            }));

            await image.SaveAsync(destPath);
        }
        catch (Exception)
        {
            // ignore thumbnail creation failures
        }
    }

    private async Task OptimizeImageAsync(string filePath)
    {
        try
        {
            using var image = await Image.LoadAsync(filePath);

            if (image.Width > 1920 || image.Height > 1080)
            {
                image.Mutate(x => x.Resize(new ResizeOptions
                {
                    Mode = ResizeMode.Max,
                    Size = new Size(1920, 1080)
                }));

                await image.SaveAsync(filePath);
            }
        }
        catch (Exception)
        {
            // ignore optimization failures
        }
    }

    private async Task<string> SaveImageFileAsync(IFormFile file, string folder = "products")
    {
        if (file == null || file.Length == 0)
            return string.Empty;

        if (!IsImageFile(file.FileName))
            throw new Exception("Invalid file format. Only images are allowed");

        if (!IsValidImageSize(file.Length, _configuration.GetValue<int>("FileSettings:MaxFileSizeMB", 5)))
            throw new Exception("File size exceeds limit");

        var fileName = GenerateUniqueFileName(file.FileName);
        var uploadFolder = Path.Combine("images", folder);
        var folderPath = Path.Combine(_environment.WebRootPath ?? string.Empty, uploadFolder);

        if (!Directory.Exists(folderPath))
            Directory.CreateDirectory(folderPath);

        var filePath = Path.Combine(folderPath, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        await OptimizeImageAsync(filePath);

        const int thumbWidth = 36;
        var scaledFileName = GetScaledFileName(fileName, thumbWidth);
        var scaledFilePath = Path.Combine(folderPath, scaledFileName);
        await CreateScaledImageAsync(filePath, scaledFilePath, thumbWidth);

        return Path.Combine(uploadFolder, fileName).Replace("\\", "/");
    }
}
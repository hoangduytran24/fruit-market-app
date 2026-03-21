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
            // Bắt đầu query
            var query = _context.Products
                .Include(p => p.Category)
                .Include(p => p.Supplier)
                .Include(p => p.Reviews)
                .AsQueryable();

            // Lọc theo từ khóa (tìm trong tên sản phẩm và mô tả)
            if (!string.IsNullOrWhiteSpace(searchDto.Keyword))
            {
                query = query.Where(p =>
                    p.ProductName.Contains(searchDto.Keyword) ||
                    (p.Description != null && p.Description.Contains(searchDto.Keyword)));
            }

            // Lọc theo danh mục
            if (!string.IsNullOrWhiteSpace(searchDto.CategoryId))
            {
                query = query.Where(p => p.CategoryId == searchDto.CategoryId);
            }

            // Lọc theo khoảng giá
            if (searchDto.MinPrice.HasValue)
            {
                query = query.Where(p => p.Price >= searchDto.MinPrice.Value);
            }

            if (searchDto.MaxPrice.HasValue)
            {
                query = query.Where(p => p.Price <= searchDto.MaxPrice.Value);
            }

            // Lọc theo tình trạng còn hàng
            if (searchDto.InStock.HasValue && searchDto.InStock.Value)
            {
                query = query.Where(p => p.StockQuantity > 0);
            }

            // Đếm tổng số bản ghi
            var totalCount = await query.CountAsync();

            // Phân trang
            var items = await query
                .OrderByDescending(p => p.CreatedAt)
                .Skip((searchDto.Page - 1) * searchDto.PageSize)
                .Take(searchDto.PageSize)
                .Select(p => new ProductListDto
                {
                    ProductId = p.ProductId,
                    ProductName = p.ProductName,
                    CategoryName = p.Category != null ? p.Category.CategoryName : string.Empty,
                    Unit = p.Unit,
                    Price = p.Price,
                    StockQuantity = p.StockQuantity,
                    ImageUrl = p.ImageUrl,
                    Description = p.Description,
                    IsActive = p.IsActive,
                    AverageRating = p.Reviews != null && p.Reviews.Any()
                        ? Math.Round(p.Reviews.Average(r => r.Rating), 1)
                        : 0,
                    ReviewCount = p.Reviews != null ? p.Reviews.Count : 0
                })
                .ToListAsync();

            // Tính tổng số trang
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
            throw;
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
                .FirstOrDefaultAsync(p => p.ProductId == id);

            if (product == null)
                return null;

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
                StockQuantity = product.StockQuantity,
                Description = product.Description,
                ImageUrl = product.ImageUrl,
                IsActive = product.IsActive,
                CreatedAt = product.CreatedAt,
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
                .Where(p => p.ProductName.Contains(keyword) && p.IsActive)
                .OrderBy(p => p.ProductName)
                .Take(20) // Giới hạn kết quả
                .Select(p => new ProductListDto
                {
                    ProductId = p.ProductId,
                    ProductName = p.ProductName,
                    CategoryName = p.Category != null ? p.Category.CategoryName : string.Empty,
                    Unit = p.Unit,
                    Price = p.Price,
                    StockQuantity = p.StockQuantity,
                    ImageUrl = p.ImageUrl,
                    AverageRating = p.Reviews != null && p.Reviews.Any()
                        ? Math.Round(p.Reviews.Average(r => r.Rating), 1)
                        : 0,
                    ReviewCount = p.Reviews != null ? p.Reviews.Count : 0
                })
                .ToListAsync();

            return products;
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
                .Where(p => p.CategoryId == categoryId && p.IsActive)
                .OrderByDescending(p => p.CreatedAt)
                .Select(p => new ProductListDto
                {
                    ProductId = p.ProductId,
                    ProductName = p.ProductName,
                    CategoryName = p.Category != null ? p.Category.CategoryName : string.Empty,
                    Unit = p.Unit,
                    Price = p.Price,
                    StockQuantity = p.StockQuantity,
                    ImageUrl = p.ImageUrl,
                    AverageRating = p.Reviews != null && p.Reviews.Any()
                        ? Math.Round(p.Reviews.Average(r => r.Rating), 1)
                        : 0,
                    ReviewCount = p.Reviews != null ? p.Reviews.Count : 0
                })
                .ToListAsync();

            return products;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting products by category: {CategoryId}", categoryId);
            throw;
        }
    }

    public async Task<IEnumerable<ProductListDto>> GetFeaturedProductsAsync(int count = 8)
    {
        try
        {
            // Lấy sản phẩm có đánh giá cao và còn hàng
            var products = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Reviews)
                .Where(p => p.IsActive && p.StockQuantity > 0)
                .OrderByDescending(p => p.Reviews != null ? p.Reviews.Average(r => r.Rating) : 0)
                .ThenByDescending(p => p.CreatedAt)
                .Take(count)
                .Select(p => new ProductListDto
                {
                    ProductId = p.ProductId,
                    ProductName = p.ProductName,
                    CategoryName = p.Category != null ? p.Category.CategoryName : string.Empty,
                    Unit = p.Unit,
                    Price = p.Price,
                    StockQuantity = p.StockQuantity,
                    ImageUrl = p.ImageUrl,
                    AverageRating = p.Reviews != null && p.Reviews.Any()
                        ? Math.Round(p.Reviews.Average(r => r.Rating), 1)
                        : 0,
                    ReviewCount = p.Reviews != null ? p.Reviews.Count : 0
                })
                .ToListAsync();

            return products;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting featured products");
            throw;
        }
    }

    public async Task<IEnumerable<ProductListDto>> GetNewestProductsAsync(int count = 8)
    {
        try
        {
            var products = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Reviews)
                .Where(p => p.IsActive)
                .OrderByDescending(p => p.CreatedAt)
                .Take(count)
                .Select(p => new ProductListDto
                {
                    ProductId = p.ProductId,
                    ProductName = p.ProductName,
                    CategoryName = p.Category != null ? p.Category.CategoryName : string.Empty,
                    Unit = p.Unit,
                    Price = p.Price,
                    StockQuantity = p.StockQuantity,
                    ImageUrl = p.ImageUrl,
                    AverageRating = p.Reviews != null && p.Reviews.Any()
                        ? Math.Round(p.Reviews.Average(r => r.Rating), 1)
                        : 0,
                    ReviewCount = p.Reviews != null ? p.Reviews.Count : 0
                })
                .ToListAsync();

            return products;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting newest products");
            throw;
        }
    }

    public async Task<IEnumerable<ProductListDto>> GetBestSellingProductsAsync(int count = 8)
    {
        try
        {
            // Lấy sản phẩm bán chạy dựa trên số lượng đã bán trong OrderItems
            var products = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.Reviews)
                .Include(p => p.OrderItems)
                .Where(p => p.IsActive)
                .OrderByDescending(p => p.OrderItems != null ? p.OrderItems.Sum(oi => oi.Quantity) : 0)
                .Take(count)
                .Select(p => new ProductListDto
                {
                    ProductId = p.ProductId,
                    ProductName = p.ProductName,
                    CategoryName = p.Category != null ? p.Category.CategoryName : string.Empty,
                    Unit = p.Unit,
                    Price = p.Price,
                    StockQuantity = p.StockQuantity,
                    ImageUrl = p.ImageUrl,
                    AverageRating = p.Reviews != null && p.Reviews.Any()
                        ? Math.Round(p.Reviews.Average(r => r.Rating), 1)
                        : 0,
                    ReviewCount = p.Reviews != null ? p.Reviews.Count : 0
                })
                .ToListAsync();

            return products;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting best selling products");
            throw;
        }
    }

    public async Task<ProductDto> CreateProductAsync(CreateProductDto createDto)
    {
        try
        {
            // Save image file (if provided) and get relative path
            string? savedImagePath = null;
            if (createDto.ImageFile != null)
            {
                savedImagePath = await SaveImageFileAsync(createDto.ImageFile, "products");
            }

            // Kiểm tra category tồn tại
            var category = await _context.Categories.FindAsync(createDto.CategoryId);
            if (category == null)
                throw new Exception($"Category with ID {createDto.CategoryId} not found");

            // Kiểm tra supplier tồn tại
            var supplier = await _context.Suppliers.FindAsync(createDto.SupplierId);
            if (supplier == null)
                throw new Exception($"Supplier with ID {createDto.SupplierId} not found");

            // Kiểm tra tên sản phẩm đã tồn tại chưa
            var existingProduct = await _context.Products
                .FirstOrDefaultAsync(p => p.ProductName.ToLower() == createDto.ProductName.ToLower());

            if (existingProduct != null)
                throw new Exception($"Product with name '{createDto.ProductName}' already exists");

            // Tạo ID mới
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
                StockQuantity = createDto.StockQuantity,
                Description = createDto.Description,
                ImageUrl = savedImagePath,
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
                StockQuantity = product.StockQuantity,
                Description = product.Description,
                ImageUrl = product.ImageUrl,
                IsActive = product.IsActive,
                CreatedAt = product.CreatedAt
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating product");
            throw;
        }
    }

    // Helper to generate simple IDs without external dependency
    private static string GenerateId(string prefix)
    {
        // Produces: PREFIX + yyMMddHHmmss + 3-digit-random (e.g. PR260309123045123)
        var ts = DateTime.UtcNow.ToString("yyMMddHHmmss");
        var rnd = _idRandom.Next(100, 1000);
        return $"{prefix}{ts}{rnd}";
    }

    public async Task<ProductDto> UpdateProductAsync(string id, UpdateProductDto updateDto)
    {
        try
        {
            // Save image file first (if provided)
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

            // Kiểm tra category tồn tại
            var category = await _context.Categories.FindAsync(updateDto.CategoryId);
            if (category == null)
                throw new Exception($"Category with ID {updateDto.CategoryId} not found");

            // Kiểm tra supplier tồn tại
            var supplier = await _context.Suppliers.FindAsync(updateDto.SupplierId);
            if (supplier == null)
                throw new Exception($"Supplier with ID {updateDto.SupplierId} not found");

            // Kiểm tra tên sản phẩm đã tồn tại chưa (trừ chính nó)
            var existingProduct = await _context.Products
                .FirstOrDefaultAsync(p => p.ProductName.ToLower() == updateDto.ProductName.ToLower()
                    && p.ProductId != id);

            if (existingProduct != null)
                throw new Exception($"Product with name '{updateDto.ProductName}' already exists");

            // Cập nhật thông tin
            product.CategoryId = updateDto.CategoryId;
            product.SupplierId = updateDto.SupplierId;
            product.ProductName = updateDto.ProductName.Trim();
            product.Unit = updateDto.Unit;
            product.Price = updateDto.Price;
            product.StockQuantity = updateDto.StockQuantity;
            product.Description = updateDto.Description;
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
                StockQuantity = product.StockQuantity,
                Description = product.Description,
                ImageUrl = product.ImageUrl,
                IsActive = product.IsActive,
                CreatedAt = product.CreatedAt
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

            // Kiểm tra xem sản phẩm có trong đơn hàng nào không
            if (product.OrderItems != null && product.OrderItems.Any())
            {
                // Nếu đã có trong đơn hàng, chỉ soft delete
                product.IsActive = false;
                _logger.LogInformation("Product soft deleted (has orders): {ProductId}", id);
            }
            else
            {
                // Nếu chưa có trong đơn hàng nào, có thể xóa cứng
                // Xóa các cart items trước
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

    public async Task<bool> RestoreProductAsync(string id)
    {
        try
        {
            var product = await _context.Products
                .FirstOrDefaultAsync(p => p.ProductId == id);

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

    // --- File helpers (moved from FileService) ---
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

        // create 36px scaled image (client expects _scaled_36)
        const int thumbWidth = 36;
        var scaledFileName = GetScaledFileName(fileName, thumbWidth);
        var scaledFilePath = Path.Combine(folderPath, scaledFileName);
        await CreateScaledImageAsync(filePath, scaledFilePath, thumbWidth);

        // SỬA: Trả về ảnh gốc thay vì ảnh scaled
        return Path.Combine(uploadFolder, fileName).Replace("\\", "/");
    }
}
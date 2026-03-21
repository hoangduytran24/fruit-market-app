using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using fruit_api.Data;
using fruit_api.DTOs.Category;
using fruit_api.Models;
using fruit_api.Services.Interfaces;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace fruit_api.Services;

public class CategoryService : ICategoryService
{
    private readonly ApplicationDbContext _context;
    private readonly IWebHostEnvironment _environment;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IConfiguration _configuration;
    private readonly ILogger<CategoryService> _logger;
    private static readonly Random _random = new();

    public CategoryService(
        ApplicationDbContext context,
        IWebHostEnvironment environment,
        IHttpContextAccessor httpContextAccessor,
        IConfiguration configuration,
        ILogger<CategoryService> logger)
    {
        _context = context;
        _environment = environment;
        _httpContextAccessor = httpContextAccessor;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<IEnumerable<CategoryDto>> GetAllCategoriesAsync()
    {
        try
        {
            // Lấy dữ liệu từ database trước
            var categories = await _context.Categories
                .OrderBy(c => c.CategoryName)
                .Select(c => new
                {
                    c.CategoryId,
                    c.CategoryName,
                    c.Description,
                    c.ImageUrl,
                    c.CreatedAt,
                    ProductCount = c.Products != null ? c.Products.Count(p => p.IsActive) : 0
                })
                .ToListAsync();

            // SỬA: Không ghép host, trả về đường dẫn tương đối
            var result = categories.Select(c => new CategoryDto
            {
                CategoryId = c.CategoryId,
                CategoryName = c.CategoryName,
                Description = c.Description,
                ImageUrl = GetImageRelativeUrl(c.ImageUrl), // Đã sửa
                CreatedAt = c.CreatedAt,
                ProductCount = c.ProductCount
            });

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all categories");
            throw;
        }
    }

    public async Task<CategoryDto?> GetCategoryByIdAsync(string id)
    {
        try
        {
            var category = await _context.Categories
                .Include(c => c.Products!.Where(p => p.IsActive))
                .FirstOrDefaultAsync(c => c.CategoryId == id);

            if (category == null)
                return null;

            // SỬA: Không ghép host, trả về đường dẫn tương đối
            return new CategoryDto
            {
                CategoryId = category.CategoryId,
                CategoryName = category.CategoryName,
                Description = category.Description,
                ImageUrl = GetImageRelativeUrl(category.ImageUrl), // Đã sửa
                CreatedAt = category.CreatedAt,
                ProductCount = category.Products?.Count ?? 0
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting category by ID: {CategoryId}", id);
            throw;
        }
    }

    public async Task<CategoryDto> CreateCategoryAsync(CreateCategoryDto createDto)
    {
        try
        {
            _logger.LogInformation("Creating new category: {CategoryName}", createDto.CategoryName);

            // Validate
            if (string.IsNullOrWhiteSpace(createDto.CategoryName))
                throw new Exception("Tên danh mục không được để trống");

            // Check if category name already exists
            var existing = await _context.Categories
                .FirstOrDefaultAsync(c => c.CategoryName.ToLower() == createDto.CategoryName.ToLower().Trim());

            if (existing != null)
                throw new Exception("Tên danh mục đã tồn tại");

            // Save image file if provided
            string? savedImagePath = null;
            if (createDto.ImageFile != null)
            {
                savedImagePath = await SaveImageFileAsync(createDto.ImageFile, "categories");
            }

            // Generate Category ID
            string categoryId = await GenerateCategoryId();

            var category = new Category
            {
                CategoryId = categoryId,
                CategoryName = createDto.CategoryName.Trim(),
                Description = createDto.Description?.Trim(),
                ImageUrl = savedImagePath,
                CreatedAt = DateTime.Now
            };

            _context.Categories.Add(category);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Category created successfully: {CategoryId} - {CategoryName}",
                category.CategoryId, category.CategoryName);

            // SỬA: Không ghép host, trả về đường dẫn tương đối
            return new CategoryDto
            {
                CategoryId = category.CategoryId,
                CategoryName = category.CategoryName,
                Description = category.Description,
                ImageUrl = GetImageRelativeUrl(category.ImageUrl), // Đã sửa
                CreatedAt = category.CreatedAt,
                ProductCount = 0
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating category");
            throw;
        }
    }

    public async Task<CategoryDto> UpdateCategoryAsync(string id, UpdateCategoryDto updateDto)
    {
        try
        {
            _logger.LogInformation("Updating category: {CategoryId}", id);

            var category = await _context.Categories.FindAsync(id);
            if (category == null)
                throw new Exception("Không tìm thấy danh mục");

            // Validate
            if (string.IsNullOrWhiteSpace(updateDto.CategoryName))
                throw new Exception("Tên danh mục không được để trống");

            // Check if new name already exists (excluding current category)
            var existing = await _context.Categories
                .FirstOrDefaultAsync(c => c.CategoryName.ToLower() == updateDto.CategoryName.ToLower().Trim()
                                       && c.CategoryId != id);

            if (existing != null)
                throw new Exception("Tên danh mục đã tồn tại");

            // Save new image if provided
            string? savedImagePath = null;
            if (updateDto.ImageFile != null)
            {
                // Delete old image if exists
                if (!string.IsNullOrEmpty(category.ImageUrl))
                {
                    DeleteImageFile(category.ImageUrl);
                }

                savedImagePath = await SaveImageFileAsync(updateDto.ImageFile, "categories");
                category.ImageUrl = savedImagePath;
            }

            // Update fields
            category.CategoryName = updateDto.CategoryName.Trim();
            category.Description = updateDto.Description?.Trim();

            await _context.SaveChangesAsync();

            _logger.LogInformation("Category updated successfully: {CategoryId}", id);

            // Get product count
            var productCount = await _context.Products.CountAsync(p => p.CategoryId == id && p.IsActive);

            // SỬA: Không ghép host, trả về đường dẫn tương đối
            return new CategoryDto
            {
                CategoryId = category.CategoryId,
                CategoryName = category.CategoryName,
                Description = category.Description,
                ImageUrl = GetImageRelativeUrl(category.ImageUrl), // Đã sửa
                CreatedAt = category.CreatedAt,
                ProductCount = productCount
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating category: {CategoryId}", id);
            throw;
        }
    }

    public async Task<bool> DeleteCategoryAsync(string id)
    {
        try
        {
            _logger.LogInformation("Deleting category: {CategoryId}", id);

            var category = await _context.Categories
                .Include(c => c.Products)
                .FirstOrDefaultAsync(c => c.CategoryId == id);

            if (category == null)
                throw new Exception("Không tìm thấy danh mục");

            // Check if category has products
            if (category.Products != null && category.Products.Any())
                throw new Exception("Không thể xóa danh mục đang có sản phẩm");

            // Delete image file if exists
            if (!string.IsNullOrEmpty(category.ImageUrl))
            {
                DeleteImageFile(category.ImageUrl);
            }

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Category deleted successfully: {CategoryId}", id);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting category: {CategoryId}", id);
            throw;
        }
    }

    // ===============================
    // Generate Category ID: CA + 6 digits (e.g., CA123456)
    // ===============================
    private async Task<string> GenerateCategoryId()
    {
        string categoryId;
        bool exists;
        int attempt = 0;
        const int maxAttempts = 10;

        do
        {
            var randomNumber = _random.Next(100000, 999999).ToString();
            categoryId = "CA" + randomNumber;
            exists = await _context.Categories.AnyAsync(c => c.CategoryId == categoryId);
            attempt++;

            if (attempt >= maxAttempts)
                throw new Exception("Không thể tạo ID danh mục duy nhất");

        } while (exists);

        return categoryId;
    }

    // ===============================
    // FILE HELPERS - SỬA: Trả về đường dẫn tương đối
    // ===============================
    private static string GetImageRelativeUrl(string? imagePath)
    {
        if (string.IsNullOrEmpty(imagePath))
            return string.Empty;

        // Đảm bảo đường dẫn bắt đầu bằng /
        if (!imagePath.StartsWith("/"))
        {
            imagePath = "/" + imagePath;
        }

        return imagePath;
    }

    // XÓA HÀM GetFullImageUrl cũ
    // private static string GetFullImageUrl(string? imagePath, HttpContext? httpContext) { ... }

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

    private async Task<string> SaveImageFileAsync(IFormFile file, string folder = "categories")
    {
        if (file == null || file.Length == 0)
            return string.Empty;

        if (!IsImageFile(file.FileName))
            throw new Exception("Chỉ chấp nhận file ảnh (jpg, jpeg, png, gif, webp)");

        if (!IsValidImageSize(file.Length, _configuration.GetValue<int>("FileSettings:MaxFileSizeMB", 5)))
            throw new Exception("Kích thước file không được vượt quá 5MB");

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

        // Optimize image
        await OptimizeImageAsync(filePath);

        // Trả về đường dẫn tương đối
        return Path.Combine(uploadFolder, fileName).Replace("\\", "/");
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
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to optimize image: {FilePath}", filePath);
        }
    }

    private void DeleteImageFile(string imageUrl)
    {
        try
        {
            if (string.IsNullOrEmpty(imageUrl))
                return;

            // Extract filename from URL
            var fileName = Path.GetFileName(imageUrl);
            var folderPath = Path.Combine(_environment.WebRootPath ?? string.Empty, "images", "categories");
            var filePath = Path.Combine(folderPath, fileName);

            if (File.Exists(filePath))
            {
                File.Delete(filePath);
                _logger.LogInformation("Deleted image file: {FileName}", fileName);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to delete image file: {ImageUrl}", imageUrl);
        }
    }
}
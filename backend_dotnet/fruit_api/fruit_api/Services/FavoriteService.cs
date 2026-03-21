using Microsoft.EntityFrameworkCore;
using fruit_api.Data;
using fruit_api.DTOs.Favorites;
using fruit_api.Models;
using fruit_api.Services.Interfaces;
using Microsoft.Extensions.Logging;

namespace fruit_api.Services;

public class FavoriteService : IFavoriteService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<FavoriteService> _logger;

    public FavoriteService(ApplicationDbContext context, ILogger<FavoriteService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<FavoriteListResponseDto> GetUserFavoritesAsync(string userId)
    {
        try
        {
            var favorites = await _context.Favorites
                .Include(f => f.Product)
                .Where(f => f.UserId == userId)
                .OrderByDescending(f => f.CreatedAt)
                .Select(f => new FavoriteDto
                {
                    FavoriteId = f.FavoriteId,
                    ProductId = f.ProductId,
                    ProductName = f.Product != null ? f.Product.ProductName : string.Empty,
                    ProductImage = f.Product != null ? f.Product.ImageUrl ?? string.Empty : string.Empty,
                    ProductPrice = f.Product != null ? f.Product.Price : 0,
                    ProductUnit = f.Product != null ? f.Product.Unit : string.Empty,
                    CreatedAt = f.CreatedAt
                })
                .ToListAsync();

            return new FavoriteListResponseDto
            {
                TotalCount = favorites.Count,
                Items = favorites
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting favorites for user {UserId}", userId);
            throw;
        }
    }

    public async Task<bool> AddFavoriteAsync(string userId, string productId)
    {
        try
        {
            // Kiểm tra product có tồn tại không
            var product = await _context.Products.FindAsync(productId);
            if (product == null)
            {
                _logger.LogWarning("Product {ProductId} not found when adding favorite for user {UserId}", productId, userId);
                return false;
            }

            // Kiểm tra đã favorite chưa
            var existing = await _context.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.ProductId == productId);

            if (existing != null)
            {
                _logger.LogWarning("Favorite already exists for user {UserId} and product {ProductId}", userId, productId);
                return false;
            }

            // Tạo favorite mới với ID được sinh tự động
            var favoriteId = await GenerateFavoriteId();

            var favorite = new Favorite
            {
                FavoriteId = favoriteId,
                UserId = userId,
                ProductId = productId,
                CreatedAt = DateTime.Now
            };

            _context.Favorites.Add(favorite);

            try
            {
                await _context.SaveChangesAsync();
                _logger.LogInformation("User {UserId} added product {ProductId} to favorites with FavoriteId {FavoriteId}",
                    userId, productId, favorite.FavoriteId);
                return true;
            }
            catch (DbUpdateException dbEx)
            {
                _logger.LogError(dbEx, "Database error when saving favorite");

                // Log chi tiết inner exception
                if (dbEx.InnerException != null)
                {
                    _logger.LogError(dbEx.InnerException, "Inner exception: {Message}", dbEx.InnerException.Message);

                    // Nếu lỗi trùng ID, thử lại với ID khác
                    if (dbEx.InnerException.Message.Contains("PK_Favorites") ||
                        dbEx.InnerException.Message.Contains("primary key") ||
                        dbEx.InnerException.Message.Contains("duplicate"))
                    {
                        _logger.LogWarning("Duplicate key detected, retrying with new ID...");

                        // Tạo ID mới và thử lại
                        var newFavoriteId = await GenerateFavoriteId(true);
                        favorite.FavoriteId = newFavoriteId;

                        await _context.SaveChangesAsync();
                        _logger.LogInformation("Successfully saved favorite with new ID: {FavoriteId}", newFavoriteId);
                        return true;
                    }
                }
                throw;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding favorite for user {UserId} with product {ProductId}", userId, productId);
            throw;
        }
    }

    public async Task<bool> RemoveFavoriteAsync(string userId, string productId)
    {
        try
        {
            var favorite = await _context.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.ProductId == productId);

            if (favorite == null)
            {
                _logger.LogWarning("Favorite not found for user {UserId} and product {ProductId}", userId, productId);
                return false;
            }

            _context.Favorites.Remove(favorite);
            await _context.SaveChangesAsync();

            _logger.LogInformation("User {UserId} removed product {ProductId} from favorites", userId, productId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error removing favorite for user {UserId} with product {ProductId}", userId, productId);
            throw;
        }
    }

    /// <summary>
    /// Sinh FavoriteId tự động theo format FAVxxxx (FAV0001, FAV0002, ...)
    /// </summary>
    private async Task<string> GenerateFavoriteId(bool forceNew = false)
    {
        try
        {
            string newId;
            bool exists;
            int attempt = 0;
            const int maxAttempts = 100; // Tránh vòng lặp vô hạn

            // Lấy tất cả ID hiện có và chuyển thành List
            var existingIds = await _context.Favorites
                .Select(f => f.FavoriteId)
                .ToListAsync();

            var existingIdSet = new HashSet<string>(existingIds);

            do
            {
                attempt++;
                if (attempt > maxAttempts)
                {
                    // Fallback: dùng timestamp nếu không thể tạo ID
                    newId = "FAV" + DateTime.Now.ToString("yyyyMMddHHmmssfff");
                    _logger.LogWarning("Using timestamp fallback ID: {FavoriteId} after {Attempts} attempts", newId, attempt);
                    return newId;
                }

                // Lấy số thứ tự cao nhất + 1
                int nextNumber = 1;

                if (existingIdSet.Any())
                {
                    // Tìm số lớn nhất từ các ID hiện có
                    var numbers = existingIdSet
                        .Where(id => id.StartsWith("FAV") && id.Length > 3)
                        .Select(id =>
                        {
                            if (int.TryParse(id.Substring(3), out int num))
                                return num;
                            return 0;
                        })
                        .ToList();

                    if (numbers.Any())
                    {
                        nextNumber = numbers.Max() + 1;
                    }
                }

                newId = "FAV" + nextNumber.ToString("D4");

                // Kiểm tra xem ID đã tồn tại chưa
                exists = existingIdSet.Contains(newId);

                if (exists)
                {
                    _logger.LogDebug("ID {FavoriteId} already exists, trying next number...", newId);
                    // Thêm ID này vào danh sách tạm thời để tránh chọn lại
                    existingIdSet.Add(newId);
                }

            } while (exists);

            _logger.LogDebug("Generated new FavoriteId: {FavoriteId} after {Attempts} attempts", newId, attempt);
            return newId;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating FavoriteId");
            // Fallback: tạo ID dựa trên timestamp nếu có lỗi
            return "FAV" + DateTime.Now.ToString("yyyyMMddHHmmssfff");
        }
    }
}
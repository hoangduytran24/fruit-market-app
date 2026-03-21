using Microsoft.EntityFrameworkCore;
using fruit_api.Data;
using fruit_api.DTOs.Review;
using fruit_api.Models;
using fruit_api.Services.Interfaces;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography;
using System.Text;

namespace fruit_api.Services;

public class ReviewService : IReviewService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ReviewService> _logger;
    private static readonly Random _random = new Random();

    public ReviewService(ApplicationDbContext context, ILogger<ReviewService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<IEnumerable<ReviewDto>> GetProductReviewsAsync(string productId)
    {
        try
        {
            return await _context.Reviews
                .Include(r => r.User)
                .Where(r => r.ProductId == productId)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new ReviewDto
                {
                    ReviewId = r.ReviewId,
                    UserId = r.UserId,
                    UserName = r.User != null ? r.User.FullName : string.Empty,
                    ProductId = r.ProductId,
                    Rating = r.Rating,
                    Comment = r.Comment,
                    CreatedAt = r.CreatedAt
                })
                .ToListAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting reviews for product {ProductId}", productId);
            throw;
        }
    }

    public async Task<ReviewDto> CreateReviewAsync(string userId, CreateReviewDto createDto)
    {
        try
        {
            _logger.LogInformation("Creating review for user {UserId}, product {ProductId}", userId, createDto.ProductId);

            // Validate rating
            if (createDto.Rating < 1 || createDto.Rating > 5)
                throw new Exception("Điểm đánh giá phải từ 1 đến 5");

            // Check if user already reviewed this product
            var existing = await _context.Reviews
                .FirstOrDefaultAsync(r => r.UserId == userId && r.ProductId == createDto.ProductId);

            if (existing != null)
                throw new Exception("Bạn đã đánh giá sản phẩm này rồi");

            // Check if product exists
            var product = await _context.Products.FindAsync(createDto.ProductId);
            if (product == null)
                throw new Exception("Sản phẩm không tồn tại");

            // ===== KIỂM TRA NGƯỜI DÙNG ĐÃ MUA SẢN PHẨM CHƯA =====
            var hasPurchased = await _context.OrderItems
                .Include(oi => oi.Order)
                .AnyAsync(oi => oi.Order != null &&
                               oi.Order.UserId == userId &&
                               oi.ProductId == createDto.ProductId &&
                               oi.Order.Status == "completed"); // Chỉ tính đơn hàng đã hoàn thành

            if (!hasPurchased)
            {
                _logger.LogWarning("User {UserId} attempted to review product {ProductId} without purchasing",
                    userId, createDto.ProductId);
                throw new Exception("Bạn chỉ có thể đánh giá sản phẩm đã mua");
            }

            // Generate unique Review ID
            string reviewId = await GenerateUniqueReviewId(userId, createDto.ProductId);

            var review = new Review
            {
                ReviewId = reviewId,
                UserId = userId,
                ProductId = createDto.ProductId,
                Rating = createDto.Rating,
                Comment = createDto.Comment,
                CreatedAt = DateTime.Now
            };

            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Review created successfully: {ReviewId}", reviewId);

            // Get user info for response
            var user = await _context.Users.FindAsync(userId);

            return new ReviewDto
            {
                ReviewId = review.ReviewId,
                UserId = review.UserId,
                UserName = user?.FullName ?? string.Empty,
                ProductId = review.ProductId,
                Rating = review.Rating,
                Comment = review.Comment,
                CreatedAt = review.CreatedAt
            };
        }
        catch (DbUpdateException dbEx)
        {
            _logger.LogError(dbEx, "Database error creating review");

            // Nếu lỗi primary key, thử lại với ID khác
            if (dbEx.InnerException != null && dbEx.InnerException.Message.Contains("PRIMARY KEY"))
            {
                // Thử lại 1 lần nữa với ID khác
                try
                {
                    string newReviewId = await GenerateUniqueReviewId(userId, createDto.ProductId, true);

                    var retryReview = new Review
                    {
                        ReviewId = newReviewId,
                        UserId = userId,
                        ProductId = createDto.ProductId,
                        Rating = createDto.Rating,
                        Comment = createDto.Comment,
                        CreatedAt = DateTime.Now
                    };

                    _context.Reviews.Add(retryReview);
                    await _context.SaveChangesAsync();

                    var user = await _context.Users.FindAsync(userId);

                    return new ReviewDto
                    {
                        ReviewId = retryReview.ReviewId,
                        UserId = retryReview.UserId,
                        UserName = user?.FullName ?? string.Empty,
                        ProductId = retryReview.ProductId,
                        Rating = retryReview.Rating,
                        Comment = retryReview.Comment,
                        CreatedAt = retryReview.CreatedAt
                    };
                }
                catch (Exception retryEx)
                {
                    _logger.LogError(retryEx, "Retry failed for review creation");
                    throw new Exception("Không thể tạo đánh giá do lỗi ID. Vui lòng thử lại.");
                }
            }

            var inner = dbEx.InnerException?.Message ?? dbEx.Message;
            throw new Exception($"Lỗi database: {inner}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating review");
            throw;
        }
    }

    public async Task<bool> DeleteReviewAsync(string id, string userId)
    {
        try
        {
            var review = await _context.Reviews.FindAsync(id);
            if (review == null)
                throw new Exception("Không tìm thấy đánh giá");

            // Check if user owns this review or is admin
            if (review.UserId != userId)
            {
                var user = await _context.Users.FindAsync(userId);
                if (user?.Role != "admin")
                    throw new UnauthorizedAccessException("Bạn không có quyền xóa đánh giá này");
            }

            _context.Reviews.Remove(review);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Review deleted: {ReviewId} by user {UserId}", id, userId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting review {ReviewId}", id);
            throw;
        }
    }

    /// <summary>
    /// Kiểm tra người dùng đã mua sản phẩm chưa
    /// </summary>
    public async Task<bool> HasUserPurchasedProductAsync(string userId, string productId)
    {
        try
        {
            return await _context.OrderItems
                .Include(oi => oi.Order)
                .AnyAsync(oi => oi.Order != null &&
                               oi.Order.UserId == userId &&
                               oi.ProductId == productId &&
                               oi.Order.Status == "completed");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking purchase for user {UserId}, product {ProductId}", userId, productId);
            throw;
        }
    }

    /// <summary>
    /// Lấy đánh giá của người dùng cho sản phẩm
    /// </summary>
    public async Task<ReviewDto?> GetUserReviewForProductAsync(string userId, string productId)
    {
        try
        {
            return await _context.Reviews
                .Include(r => r.User)
                .Where(r => r.UserId == userId && r.ProductId == productId)
                .Select(r => new ReviewDto
                {
                    ReviewId = r.ReviewId,
                    UserId = r.UserId,
                    UserName = r.User != null ? r.User.FullName : string.Empty,
                    ProductId = r.ProductId,
                    Rating = r.Rating,
                    Comment = r.Comment,
                    CreatedAt = r.CreatedAt
                })
                .FirstOrDefaultAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting user review for product");
            throw;
        }
    }

    // ===============================
    // Generate Unique Review ID với nhiều phương pháp
    // ===============================
    private async Task<string> GenerateUniqueReviewId(string userId, string productId, bool force = false)
    {
        string reviewId;
        bool exists;
        int maxAttempts = 10;
        int attempt = 0;

        do
        {
            // Phương pháp 1: Dùng Guid (đảm bảo unique gần như tuyệt đối)
            if (attempt < 3 || force)
            {
                // REV + 8 ký tự từ Guid
                reviewId = "REV" + Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper();
            }
            // Phương pháp 2: Dùng timestamp + random
            else if (attempt < 6)
            {
                var timestamp = DateTime.Now.ToString("yyMMddHHmmss");
                var random = _random.Next(100, 9999);
                reviewId = "REV" + timestamp + random;
            }
            // Phương pháp 3: Dùng hash từ userId + productId + timestamp
            else
            {
                var input = $"{userId}{productId}{DateTime.Now.Ticks}{_random.Next()}";
                using var md5 = MD5.Create();
                var hash = md5.ComputeHash(Encoding.UTF8.GetBytes(input ?? string.Empty));
                var hashString = BitConverter.ToString(hash).Replace("-", "").Substring(0, 8);
                reviewId = "REV" + hashString;
            }

            // Đảm bảo không quá 20 ký tự
            if (reviewId.Length > 20)
                reviewId = reviewId.Substring(0, 20);

            // Kiểm tra trong database
            exists = await _context.Reviews.AnyAsync(r => r.ReviewId == reviewId);
            attempt++;

            if (attempt >= maxAttempts)
                throw new Exception("Không thể tạo ID duy nhất sau nhiều lần thử");

        } while (exists);

        return reviewId;
    }

    // Phương pháp đơn giản nhất - khuyên dùng
    private async Task<string> GenerateSimpleReviewId()
    {
        string reviewId;
        bool exists;
        int attempt = 0;

        do
        {
            // Tạo ID: REV + timestamp + random
            var timestamp = DateTime.Now.ToString("yyMMddHHmmss");
            var random = _random.Next(1000, 9999);
            reviewId = "REV" + timestamp + random;

            // Đảm bảo không quá 20 ký tự
            if (reviewId.Length > 20)
                reviewId = reviewId.Substring(0, 20);

            // Kiểm tra tồn tại
            exists = await _context.Reviews.AnyAsync(r => r.ReviewId == reviewId);
            attempt++;

            if (attempt > 5)
                throw new Exception("Không thể tạo ID duy nhất");

        } while (exists);

        return reviewId;
    }
}
using fruit_api.DTOs.Review;

namespace fruit_api.Services.Interfaces;

public interface IReviewService
{
    Task<IEnumerable<ReviewDto>> GetProductReviewsAsync(string productId);
    Task<ReviewDto> CreateReviewAsync(string userId, CreateReviewDto createDto);
    Task<bool> DeleteReviewAsync(string id, string userId);
    Task<bool> HasUserPurchasedProductAsync(string userId, string productId); // Thêm mới
    Task<ReviewDto?> GetUserReviewForProductAsync(string userId, string productId); // Thêm mới
}
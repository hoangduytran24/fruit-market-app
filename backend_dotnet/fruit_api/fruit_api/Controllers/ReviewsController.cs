using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using fruit_api.DTOs.Review;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ReviewsController : ControllerBase
{
    private readonly IReviewService _reviewService;

    public ReviewsController(IReviewService reviewService)
    {
        _reviewService = reviewService;
    }

    /// <summary>
    /// Lấy danh sách đánh giá của sản phẩm
    /// </summary>
    [HttpGet("product/{productId}")]
    public async Task<IActionResult> GetProductReviews(string productId)
    {
        var reviews = await _reviewService.GetProductReviewsAsync(productId);
        return Ok(reviews);
    }

    /// <summary>
    /// Tạo đánh giá mới
    /// </summary>
    [HttpPost]
    [Authorize]
    public async Task<IActionResult> CreateReview(CreateReviewDto createDto)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
                return Unauthorized(new { message = "Vui lòng đăng nhập" });

            var review = await _reviewService.CreateReviewAsync(userId, createDto);
            return Ok(review);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Xóa đánh giá
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> DeleteReview(string id)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
                return Unauthorized(new { message = "Vui lòng đăng nhập" });

            await _reviewService.DeleteReviewAsync(id, userId);
            return Ok(new { message = "Xóa đánh giá thành công" });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Kiểm tra người dùng đã mua sản phẩm chưa
    /// </summary>
    [HttpGet("check-purchase")]
    [Authorize]
    public async Task<IActionResult> CheckUserPurchased([FromQuery] string productId)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
                return Unauthorized(new { message = "Vui lòng đăng nhập" });

            var hasPurchased = await _reviewService.HasUserPurchasedProductAsync(userId, productId);
            return Ok(new { hasPurchased = hasPurchased });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = ex.Message });
        }
    }
}
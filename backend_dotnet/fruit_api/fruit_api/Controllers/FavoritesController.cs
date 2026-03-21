using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using fruit_api.DTOs.Favorites;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[Route("api/favorites")]
[ApiController]
[Authorize]
public class FavoritesController : ControllerBase
{
    private readonly IFavoriteService _favoriteService;

    public FavoritesController(IFavoriteService favoriteService)
    {
        _favoriteService = favoriteService;
    }

    /// <summary>
    /// Lấy danh sách sản phẩm yêu thích
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetMyFavorites()
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Không tìm thấy thông tin người dùng" });

            var result = await _favoriteService.GetUserFavoritesAsync(userId);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Thêm sản phẩm vào yêu thích
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> AddFavorite(CreateFavoriteDto createDto)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Không tìm thấy thông tin người dùng" });

            var result = await _favoriteService.AddFavoriteAsync(userId, createDto.ProductId);
            if (result)
                return Ok(new { message = "Đã thêm vào danh sách yêu thích" });

            return BadRequest(new { message = "Không thể thêm sản phẩm vào danh sách yêu thích" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Xóa sản phẩm khỏi yêu thích
    /// </summary>
    [HttpDelete("{productId}")]
    public async Task<IActionResult> RemoveFavorite(string productId)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Không tìm thấy thông tin người dùng" });

            var result = await _favoriteService.RemoveFavoriteAsync(userId, productId);
            if (result)
                return Ok(new { message = "Đã xóa khỏi danh sách yêu thích" });

            return NotFound(new { message = "Không tìm thấy sản phẩm trong danh sách yêu thích" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
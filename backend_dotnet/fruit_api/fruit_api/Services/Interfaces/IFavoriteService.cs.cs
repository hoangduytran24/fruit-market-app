using fruit_api.DTOs.Favorites;

namespace fruit_api.Services.Interfaces;

public interface IFavoriteService
{
    Task<FavoriteListResponseDto> GetUserFavoritesAsync(string userId);
    Task<bool> AddFavoriteAsync(string userId, string productId);
    Task<bool> RemoveFavoriteAsync(string userId, string productId);
}
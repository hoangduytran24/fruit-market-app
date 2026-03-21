using fruit_api.DTOs.Cart;

namespace fruit_api.Services.Interfaces;

public interface ICartService
{
    Task<CartDto> GetCartAsync(string userId);
    Task<CartDto> AddToCartAsync(string userId, AddToCartDto addToCartDto);
    Task<CartDto> UpdateCartItemAsync(string userId, string productId, UpdateCartItemDto updateDto);
    Task<bool> RemoveFromCartAsync(string userId, string productId);
    Task<bool> ClearCartAsync(string userId);
}
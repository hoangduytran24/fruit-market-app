using fruit_api.DTOs.Order;

namespace fruit_api.Services.Interfaces;

public interface IOrderService
{
    Task<IEnumerable<OrderListDto>> GetUserOrdersAsync(string userId);
    Task<IEnumerable<OrderListDto>> GetAllOrdersAsync(string? status = null);
    Task<OrderDto?> GetOrderByIdAsync(string id);
    Task<OrderDto> CreateOrderAsync(string userId, CreateOrderDto createOrderDto);
    Task<OrderDto> BuyNowAsync(string userId, BuyNowDto buyNowDto);
    Task<OrderDto> UpdateOrderStatusAsync(string id, UpdateOrderStatusDto updateDto);
    Task<bool> CancelOrderAsync(string id);
}
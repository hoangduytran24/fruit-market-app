using fruit_api.DTOs.Statistics;

namespace fruit_api.Services.Interfaces;

public interface IStatisticsService
{
    Task<DashboardStatisticsDto> GetDashboardStatisticsAsync();
    Task<IEnumerable<RevenueStatisticsDto>> GetRevenueStatisticsAsync(string period, int? year, int? month);
    Task<IEnumerable<TopProductDto>> GetTopProductsAsync(int top = 10, string? period = "month");
    Task<OrderStatusStatisticsDto> GetOrderStatusStatisticsAsync();
    Task<UserStatisticsDto> GetUserStatisticsAsync();
}
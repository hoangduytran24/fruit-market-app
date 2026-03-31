using Microsoft.EntityFrameworkCore;
using fruit_api.Data;
using fruit_api.DTOs.Statistics;
using fruit_api.Services.Interfaces;

namespace fruit_api.Services;

public class StatisticsService : IStatisticsService
{
    private readonly ApplicationDbContext _context;

    public StatisticsService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<DashboardStatisticsDto> GetDashboardStatisticsAsync()
    {
        var today = DateTime.UtcNow.Date;
        var tomorrow = today.AddDays(1);

        var dashboard = new DashboardStatisticsDto
        {
            TotalOrders = await _context.Orders.CountAsync(),
            TotalUsers = await _context.Users.CountAsync(),
            TotalProducts = await _context.Products.CountAsync(),
            TotalRevenue = await _context.Orders
                .Where(o => o.Status == "completed")
                .SumAsync(o => (decimal)o.FinalAmount),
            TodayRevenue = await _context.Orders
                .Where(o => o.Status == "completed" && o.CreatedAt >= today && o.CreatedAt < tomorrow)
                .SumAsync(o => (decimal)o.FinalAmount),
            TodayOrders = await _context.Orders
                .CountAsync(o => o.CreatedAt >= today && o.CreatedAt < tomorrow),
            PendingOrders = await _context.Orders
                .CountAsync(o => o.Status == "pending"),
            LowStockProducts = await _context.Products
                .CountAsync(p => p.StockQuantity > 0 && p.StockQuantity <= 10)
        };

        return dashboard;
    }

    public async Task<IEnumerable<RevenueStatisticsDto>> GetRevenueStatisticsAsync(string period, int? year, int? month)
    {
        var currentYear = year ?? DateTime.UtcNow.Year;
        var query = _context.Orders
            .Where(o => o.Status == "completed")
            .AsQueryable();

        var result = new List<RevenueStatisticsDto>();

        switch (period.ToLower())
        {
            case "day":
                var startDate = DateTime.UtcNow.AddDays(-29).Date;
                for (int i = 0; i < 30; i++)
                {
                    var date = startDate.AddDays(i);
                    var nextDate = date.AddDays(1);
                    var revenue = await query
                        .Where(o => o.CreatedAt >= date && o.CreatedAt < nextDate)
                        .SumAsync(o => (decimal)o.FinalAmount);
                    var orderCount = await query
                        .CountAsync(o => o.CreatedAt >= date && o.CreatedAt < nextDate);

                    result.Add(new RevenueStatisticsDto
                    {
                        Date = date,
                        Revenue = revenue,
                        OrderCount = orderCount
                    });
                }
                break;

            case "month":
                for (int i = 1; i <= 12; i++)
                {
                    var date = new DateTime(currentYear, i, 1);
                    var nextMonth = date.AddMonths(1);
                    var revenue = await query
                        .Where(o => o.CreatedAt >= date && o.CreatedAt < nextMonth)
                        .SumAsync(o => (decimal)o.FinalAmount);
                    var orderCount = await query
                        .CountAsync(o => o.CreatedAt >= date && o.CreatedAt < nextMonth);

                    result.Add(new RevenueStatisticsDto
                    {
                        Date = date,
                        Revenue = revenue,
                        OrderCount = orderCount
                    });
                }
                break;

            case "year":
                var currentYear5 = DateTime.UtcNow.Year;
                for (int i = currentYear5 - 4; i <= currentYear5; i++)
                {
                    var date = new DateTime(i, 1, 1);
                    var nextYear = date.AddYears(1);
                    var revenue = await query
                        .Where(o => o.CreatedAt >= date && o.CreatedAt < nextYear)
                        .SumAsync(o => (decimal)o.FinalAmount);
                    var orderCount = await query
                        .CountAsync(o => o.CreatedAt >= date && o.CreatedAt < nextYear);

                    result.Add(new RevenueStatisticsDto
                    {
                        Date = date,
                        Revenue = revenue,
                        OrderCount = orderCount
                    });
                }
                break;
        }

        return result;
    }

    public async Task<IEnumerable<TopProductDto>> GetTopProductsAsync(int top = 10, string? period = "month")
    {
        var startDate = period switch
        {
            "week" => DateTime.UtcNow.AddDays(-7),
            "month" => DateTime.UtcNow.AddMonths(-1),
            "year" => DateTime.UtcNow.AddYears(-1),
            _ => DateTime.UtcNow.AddMonths(-1)
        };

        var topProducts = await _context.OrderItems
            .Include(oi => oi.Product)
            .Where(oi => oi.Order != null && oi.Order.Status == "completed" && oi.Order.CreatedAt >= startDate)
            .GroupBy(oi => new { oi.ProductId, oi.Product!.ProductName, oi.Product!.ImageUrl })
            .Select(g => new TopProductDto
            {
                ProductId = g.Key.ProductId,
                ProductName = g.Key.ProductName,
                TotalQuantitySold = g.Sum(oi => oi.Quantity),
                TotalRevenue = g.Sum(oi => oi.Quantity * oi.PriceAtTime),
                ImageUrl = g.Key.ImageUrl ?? ""
            })
            .OrderByDescending(p => p.TotalQuantitySold)
            .Take(top)
            .ToListAsync();

        return topProducts;
    }

    public async Task<OrderStatusStatisticsDto> GetOrderStatusStatisticsAsync()
    {
        var statistics = new OrderStatusStatisticsDto
        {
            Pending = await _context.Orders.CountAsync(o => o.Status == "pending"),
            Processing = await _context.Orders.CountAsync(o => o.Status == "processing"),
            Shipping = await _context.Orders.CountAsync(o => o.Status == "shipping"),
            Completed = await _context.Orders.CountAsync(o => o.Status == "completed"),
            Cancelled = await _context.Orders.CountAsync(o => o.Status == "cancelled")
        };

        return statistics;
    }

    public async Task<OrderStatisticsDto> GetOrderStatisticsAsync()
    {
        var statistics = new OrderStatisticsDto
        {
            Total = await _context.Orders.CountAsync(),
            Pending = await _context.Orders.CountAsync(o => o.Status == "pending"),
            Processing = await _context.Orders.CountAsync(o => o.Status == "processing"),
            Shipping = await _context.Orders.CountAsync(o => o.Status == "shipping"),
            Completed = await _context.Orders.CountAsync(o => o.Status == "completed"),
            Cancelled = await _context.Orders.CountAsync(o => o.Status == "cancelled")
        };

        return statistics;
    }
}
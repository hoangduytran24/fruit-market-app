using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using fruit_api.DTOs.Statistics;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "admin")]
public class StatisticsController : ControllerBase
{
    private readonly IStatisticsService _statisticsService;

    public StatisticsController(IStatisticsService statisticsService)
    {
        _statisticsService = statisticsService;
    }

    /// <summary>
    /// Lấy thống kê dashboard tổng quan
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboardStatistics()
    {
        var stats = await _statisticsService.GetDashboardStatisticsAsync();
        return Ok(stats);
    }

    /// <summary>
    /// Lấy thống kê doanh thu theo ngày/tháng/năm
    /// </summary>
    [HttpGet("revenue")]
    public async Task<IActionResult> GetRevenueStatistics(
        [FromQuery] string period = "month",
        [FromQuery] int? year = null,
        [FromQuery] int? month = null)
    {
        var stats = await _statisticsService.GetRevenueStatisticsAsync(period, year, month);
        return Ok(stats);
    }

    /// <summary>
    /// Lấy top sản phẩm bán chạy
    /// </summary>
    [HttpGet("top-products")]
    public async Task<IActionResult> GetTopProducts(
        [FromQuery] int top = 10,
        [FromQuery] string period = "month")
    {
        var products = await _statisticsService.GetTopProductsAsync(top, period);
        return Ok(products);
    }

    /// <summary>
    /// Lấy thống kê trạng thái đơn hàng
    /// </summary>
    [HttpGet("order-status")]
    public async Task<IActionResult> GetOrderStatusStatistics()
    {
        var stats = await _statisticsService.GetOrderStatusStatisticsAsync();
        return Ok(stats);
    }

    /// <summary>
    /// Lấy thống kê tổng hợp đơn hàng
    /// </summary>
    [HttpGet("orders")]
    public async Task<IActionResult> GetOrderStatistics()
    {
        var stats = await _statisticsService.GetOrderStatisticsAsync();
        return Ok(stats);
    }
}
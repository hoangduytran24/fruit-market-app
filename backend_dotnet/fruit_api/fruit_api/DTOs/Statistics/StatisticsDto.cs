using System;

namespace fruit_api.DTOs.Statistics;

// ===============================
// DASHBOARD STATISTICS
// ===============================

public class DashboardStatisticsDto
{
    public int TotalOrders { get; set; }           // Tổng đơn hàng
    public int TotalUsers { get; set; }             // Tổng người dùng
    public int TotalProducts { get; set; }          // Tổng sản phẩm
    public decimal TotalRevenue { get; set; }       // Tổng doanh thu
    public decimal TodayRevenue { get; set; }       // Doanh thu hôm nay
    public int TodayOrders { get; set; }            // Đơn hàng hôm nay
    public int PendingOrders { get; set; }          // Đơn chờ duyệt
    public int LowStockProducts { get; set; }       // Sản phẩm sắp hết hàng
}

// ===============================
// REVENUE STATISTICS
// ===============================

public class RevenueStatisticsDto
{
    public DateTime Date { get; set; }
    public decimal Revenue { get; set; }
    public int OrderCount { get; set; }
}

// ===============================
// TOP PRODUCTS STATISTICS
// ===============================

public class TopProductDto
{
    public string ProductId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public int TotalQuantitySold { get; set; }
    public decimal TotalRevenue { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
}

// ===============================
// ORDER STATUS STATISTICS
// ===============================

public class OrderStatusStatisticsDto
{
    public int Pending { get; set; }
    public int Processing { get; set; }
    public int Shipping { get; set; }
    public int Completed { get; set; }
    public int Cancelled { get; set; }
}

// ===============================
// USER STATISTICS
// ===============================

public class UserStatisticsDto
{
    public int Total { get; set; }
    public int Active { get; set; }
    public int Inactive { get; set; }
    public int Banned { get; set; }
    public int Customers { get; set; }
    public int Admins { get; set; }
}
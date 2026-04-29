using System;

namespace fruit_api.DTOs.Statistics;

// ===============================
// DASHBOARD STATISTICS
// ===============================

public class DashboardStatisticsDto
{
    public int TotalOrders { get; set; }
    public int TotalUsers { get; set; }
    public int TotalProducts { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal TodayRevenue { get; set; }
    public int TodayOrders { get; set; }
    public int PendingOrders { get; set; }
    public int LowStockProducts { get; set; }
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
// ORDER STATISTICS (TỔNG HỢP ĐƠN HÀNG)
// ===============================

public class OrderStatisticsDto
{
    public int Total { get; set; }      // Tổng số đơn hàng
    public int Pending { get; set; }    // Đơn chờ duyệt
    public int Processing { get; set; } // Đơn đang xử lý
    public int Shipping { get; set; }   // Đơn đang giao
    public int Completed { get; set; }  // Đơn thành công
    public int Cancelled { get; set; }  // Đơn đã hủy
}
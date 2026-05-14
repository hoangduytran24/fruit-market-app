using System;

namespace fruit_api.DTOs.Inventory;

public class InventoryListDto
{
    public string InventoryId { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string ProductImage { get; set; } = string.Empty;
    public string BatchCode { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public DateTime? ManufactureDate { get; set; }
    public DateTime ExpiryDate { get; set; }
    public decimal? ImportPrice { get; set; }
    public DateTime ImportDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusText { get; set; } = string.Empty;
    public bool IsExpired { get; set; }
    public int DaysToExpiry { get; set; }
}

// DTO cho chi tiết 1 lô hàng
public class InventoryDetailDto
{
    public string InventoryId { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string ProductImage { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public string SupplierName { get; set; } = string.Empty;
    public string BatchCode { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public DateTime? ManufactureDate { get; set; }
    public DateTime ExpiryDate { get; set; }
    public decimal? ImportPrice { get; set; }
    public DateTime ImportDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusText { get; set; } = string.Empty;
    public bool IsExpired { get; set; }
    public int DaysToExpiry { get; set; }
    public DateTime CreatedAt { get; set; }
}

// DTO cho tạo lô hàng mới
public class CreateInventoryDto
{
    public string ProductId { get; set; } = string.Empty;
    public string BatchCode { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public DateTime? ManufactureDate { get; set; }
    public DateTime ExpiryDate { get; set; }
    public decimal? ImportPrice { get; set; }
}

// DTO cho cập nhật lô hàng
public class UpdateInventoryDto
{
    public int? Quantity { get; set; }
    public DateTime? ManufactureDate { get; set; }
    public DateTime? ExpiryDate { get; set; }
    public decimal? ImportPrice { get; set; }
    public string? Status { get; set; }
}

// DTO cho xuất kho (khi bán hàng)
public class ExportInventoryDto
{
    public string InventoryId { get; set; } = string.Empty;
    public int Quantity { get; set; }
}

// DTO cho nhập kho mới
public class ImportInventoryDto
{
    public string ProductId { get; set; } = string.Empty;
    public string BatchCode { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public DateTime? ManufactureDate { get; set; }
    public DateTime ExpiryDate { get; set; }
    public decimal? ImportPrice { get; set; }
}

// DTO cho kiểm tra hạn sử dụng - ĐÃ SỬA: Thêm ImportPrice
public class ExpiryCheckDto
{
    public string InventoryId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string BatchCode { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public DateTime ExpiryDate { get; set; }
    public int DaysToExpiry { get; set; }
    public bool IsExpired { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal? ImportPrice { get; set; }  // ⭐ ĐÃ THÊM - Fix lỗi isNegative
}

// DTO cho thống kê tồn kho theo hạn sử dụng
public class InventoryStatisticsDto
{
    public string ProductId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public int TotalInStock { get; set; }
    public int TotalExpired { get; set; }
    public int TotalSoldOut { get; set; }
    public int ExpiringIn7Days { get; set; }    // Sắp hết hạn trong 7 ngày
    public int ExpiringIn30Days { get; set; }   // Sắp hết hạn trong 30 ngày
}
namespace fruit_api.DTOs.Supplier;

public class SupplierDto
{
    public string SupplierId { get; set; } = string.Empty;
    public string SupplierName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public int ProductCount { get; set; }
}

public class CreateSupplierDto
{
    public string SupplierName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
}

public class UpdateSupplierDto
{
    public string SupplierName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public string Status { get; set; } = "active";
}
using System.ComponentModel.DataAnnotations;

namespace fruit_api.DTOs.Supplier;

public class SupplierDto
{
    public string SupplierId { get; set; } = string.Empty;
    public string SupplierName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Email { get; set; }  // THÊM DÒNG NÀY
    public string? Address { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public int ProductCount { get; set; }
}

public class CreateSupplierDto
{
    [Required(ErrorMessage = "Tên nhà cung cấp là bắt buộc")]
    [MaxLength(150, ErrorMessage = "Tên nhà cung cấp không quá 150 ký tự")]
    public string SupplierName { get; set; } = string.Empty;

    [MaxLength(15, ErrorMessage = "Số điện thoại không quá 15 ký tự")]
    public string? Phone { get; set; }

    [MaxLength(100, ErrorMessage = "Email không quá 100 ký tự")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string? Email { get; set; }  // THÊM DÒNG NÀY

    [MaxLength(255, ErrorMessage = "Địa chỉ không quá 255 ký tự")]
    public string? Address { get; set; }
}

public class UpdateSupplierDto
{
    [Required(ErrorMessage = "Tên nhà cung cấp là bắt buộc")]
    [MaxLength(150, ErrorMessage = "Tên nhà cung cấp không quá 150 ký tự")]
    public string SupplierName { get; set; } = string.Empty;

    [MaxLength(15, ErrorMessage = "Số điện thoại không quá 15 ký tự")]
    public string? Phone { get; set; }

    [MaxLength(100, ErrorMessage = "Email không quá 100 ký tự")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string? Email { get; set; }  // THÊM DÒNG NÀY

    [MaxLength(255, ErrorMessage = "Địa chỉ không quá 255 ký tự")]
    public string? Address { get; set; }

    [Required(ErrorMessage = "Trạng thái là bắt buộc")]
    public string Status { get; set; } = "active";
}
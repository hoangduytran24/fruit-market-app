using fruit_api.DTOs.Review;
using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace fruit_api.DTOs.Product;

public class ProductDto
{
    public string ProductId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string CategoryId { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public string SupplierId { get; set; } = string.Empty;
    public string SupplierName { get; set; } = string.Empty;
    public string SupplierAddress { get; set; } = string.Empty;  // THÊM DÒNG NÀY
    public string Unit { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class ProductListDto
{
    public string ProductId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string CategoryId { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public string SupplierId { get; set; } = string.Empty;
    public string SupplierName { get; set; } = string.Empty;
    public string SupplierAddress { get; set; } = string.Empty;  // THÊM DÒNG NÀY
    public string Unit { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public string? ImageUrl { get; set; }
    public string? Description { get; set; }
    public double AverageRating { get; set; }
    public int ReviewCount { get; set; }
    public bool IsActive { get; set; }
}

public class ProductDetailDto : ProductDto
{
    public List<ReviewDto> Reviews { get; set; } = new();
    public double AverageRating { get; set; }
    public int ReviewCount { get; set; }
}

public class CreateProductDto
{
    [Required(ErrorMessage = "Category is required")]
    public string CategoryId { get; set; } = string.Empty;

    [Required(ErrorMessage = "Supplier is required")]
    public string SupplierId { get; set; } = string.Empty;

    [Required(ErrorMessage = "Product name is required")]
    [MaxLength(150, ErrorMessage = "Product name cannot exceed 150 characters")]
    public string ProductName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Unit is required")]
    [MaxLength(50, ErrorMessage = "Unit cannot exceed 50 characters")]
    public string Unit { get; set; } = string.Empty;

    [Required(ErrorMessage = "Price is required")]
    [Range(0, double.MaxValue, ErrorMessage = "Price must be greater than or equal to 0")]
    public decimal Price { get; set; }

    [Range(0, int.MaxValue, ErrorMessage = "Stock quantity must be greater than or equal to 0")]
    public int StockQuantity { get; set; }

    public string? Description { get; set; }

    // removed manual ImageUrl input: only file upload is allowed when creating
    public IFormFile? ImageFile { get; set; }
}

public class UpdateProductDto
{
    [Required(ErrorMessage = "Category is required")]
    public string CategoryId { get; set; } = string.Empty;

    [Required(ErrorMessage = "Supplier is required")]
    public string SupplierId { get; set; } = string.Empty;

    [Required(ErrorMessage = "Product name is required")]
    [MaxLength(150, ErrorMessage = "Product name cannot exceed 150 characters")]
    public string ProductName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Unit is required")]
    [MaxLength(50, ErrorMessage = "Unit cannot exceed 50 characters")]
    public string Unit { get; set; } = string.Empty;

    [Required(ErrorMessage = "Price is required")]
    [Range(0, double.MaxValue, ErrorMessage = "Price must be greater than or equal to 0")]
    public decimal Price { get; set; }

    [Range(0, int.MaxValue, ErrorMessage = "Stock quantity must be greater than or equal to 0")]
    public int StockQuantity { get; set; }

    public string? Description { get; set; }

    // removed manual ImageUrl input: use ImageFile to update the product image
    public IFormFile? ImageFile { get; set; }

    public bool IsActive { get; set; }
}

public class ProductSearchDto
{
    public string? Keyword { get; set; }
    public string? CategoryId { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public bool? InStock { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}

public class ProductResponseDto
{
    public List<ProductListDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
}
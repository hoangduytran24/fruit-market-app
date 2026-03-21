using Microsoft.AspNetCore.Http;

namespace fruit_api.DTOs.Category;

public class CategoryDto
{
    public string CategoryId { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public DateTime CreatedAt { get; set; }
    public int ProductCount { get; set; }
}

public class CreateCategoryDto
{
    public string CategoryName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public IFormFile? ImageFile { get; set; }  // Thay ImageUrl bằng ImageFile
}

public class UpdateCategoryDto
{
    public string CategoryName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public IFormFile? ImageFile { get; set; }  // Thêm để upload ảnh mới
}
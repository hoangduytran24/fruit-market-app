using fruit_api.DTOs.Category;

namespace fruit_api.Services.Interfaces;

public interface ICategoryService
{
    Task<IEnumerable<CategoryDto>> GetAllCategoriesAsync();
    Task<CategoryDto?> GetCategoryByIdAsync(string id);
    Task<CategoryDto> CreateCategoryAsync(CreateCategoryDto createDto);
    Task<CategoryDto> UpdateCategoryAsync(string id, UpdateCategoryDto updateDto);
    Task<bool> DeleteCategoryAsync(string id);
}
using fruit_api.DTOs.Product;

namespace fruit_api.Services.Interfaces;

public interface IProductService
{
    // Lấy tất cả sản phẩm (có phân trang và tìm kiếm)
    Task<ProductResponseDto> GetAllProductsAsync(ProductSearchDto searchDto);

    // Lấy sản phẩm theo ID
    Task<ProductDetailDto?> GetProductByIdAsync(string id);

    // Tìm kiếm sản phẩm theo tên
    Task<IEnumerable<ProductListDto>> SearchProductsByNameAsync(string keyword);

    // Lấy sản phẩm theo danh mục
    Task<IEnumerable<ProductListDto>> GetProductsByCategoryAsync(string categoryId);

    // Lấy sản phẩm nổi bật
    Task<IEnumerable<ProductListDto>> GetFeaturedProductsAsync(int count = 8);

    // Lấy sản phẩm mới nhất
    Task<IEnumerable<ProductListDto>> GetNewestProductsAsync(int count = 8);

    // Lấy sản phẩm bán chạy
    Task<IEnumerable<ProductListDto>> GetBestSellingProductsAsync(int count = 8);

    // Thêm sản phẩm mới
    Task<ProductDto> CreateProductAsync(CreateProductDto createDto);

    // Cập nhật sản phẩm
    Task<ProductDto> UpdateProductAsync(string id, UpdateProductDto updateDto);

    // Xóa sản phẩm (soft delete)
    Task<bool> DeleteProductAsync(string id);

    // Khôi phục sản phẩm đã xóa
    Task<bool> RestoreProductAsync(string id);

    // Cập nhật số lượng tồn kho
    Task<bool> UpdateStockAsync(string id, int quantity);

    // Kiểm tra sản phẩm còn hàng không
    Task<bool> IsInStockAsync(string id, int quantity = 1);
}
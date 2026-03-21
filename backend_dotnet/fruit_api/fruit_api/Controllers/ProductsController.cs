using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using fruit_api.DTOs.Product;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(
        IProductService productService,
        ILogger<ProductsController> logger)
    {
        _productService = productService;
        _logger = logger;
    }

    /// <summary>
    /// Lấy danh sách sản phẩm với phân trang và tìm kiếm
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] ProductSearchDto searchDto)
    {
        try
        {
            var result = await _productService.GetAllProductsAsync(searchDto);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting products");
            return StatusCode(500, new { message = "An error occurred while getting products" });
        }
    }

    /// <summary>
    /// Tìm kiếm sản phẩm theo tên
    /// </summary>
    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] string keyword)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(keyword))
                return Ok(new List<ProductListDto>());

            var products = await _productService.SearchProductsByNameAsync(keyword);
            return Ok(products);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error searching products");
            return StatusCode(500, new { message = "An error occurred while searching products" });
        }
    }

    /// <summary>
    /// Lấy sản phẩm theo danh mục
    /// </summary>
    [HttpGet("category/{categoryId}")]
    public async Task<IActionResult> GetByCategory(string categoryId)
    {
        try
        {
            var products = await _productService.GetProductsByCategoryAsync(categoryId);
            return Ok(products);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting products by category");
            return StatusCode(500, new { message = "An error occurred while getting products" });
        }
    }

    /// <summary>
    /// Lấy sản phẩm nổi bật
    /// </summary>
    [HttpGet("featured")]
    public async Task<IActionResult> GetFeatured([FromQuery] int count = 8)
    {
        try
        {
            var products = await _productService.GetFeaturedProductsAsync(count);
            return Ok(products);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting featured products");
            return StatusCode(500, new { message = "An error occurred while getting featured products" });
        }
    }

    /// <summary>
    /// Lấy sản phẩm mới nhất
    /// </summary>
    [HttpGet("newest")]
    public async Task<IActionResult> GetNewest([FromQuery] int count = 8)
    {
        try
        {
            var products = await _productService.GetNewestProductsAsync(count);
            return Ok(products);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting newest products");
            return StatusCode(500, new { message = "An error occurred while getting newest products" });
        }
    }

    /// <summary>
    /// Lấy sản phẩm bán chạy
    /// </summary>
    [HttpGet("best-selling")]
    public async Task<IActionResult> GetBestSelling([FromQuery] int count = 8)
    {
        try
        {
            var products = await _productService.GetBestSellingProductsAsync(count);
            return Ok(products);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting best selling products");
            return StatusCode(500, new { message = "An error occurred while getting best selling products" });
        }
    }

    /// <summary>
    /// Lấy chi tiết sản phẩm theo ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        try
        {
            var product = await _productService.GetProductByIdAsync(id);
            if (product == null)
                return NotFound(new { message = $"Product with ID {id} not found" });

            return Ok(product);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting product by ID: {ProductId}", id);
            return StatusCode(500, new { message = "An error occurred while getting product" });
        }
    }

    /// <summary>
    /// Thêm sản phẩm mới (chỉ admin)
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Create([FromForm] CreateProductDto createDto)
    {
        try
        {
            // Validate dữ liệu đầu vào
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var product = await _productService.CreateProductAsync(createDto);

            _logger.LogInformation("Product created by admin: {ProductId}", product.ProductId);

            return CreatedAtAction(nameof(GetById), new { id = product.ProductId }, product);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating product");
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Cập nhật sản phẩm (chỉ admin)
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Update(string id, [FromForm] UpdateProductDto updateDto)
    {
        try
        {
            // Validate dữ liệu đầu vào
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var product = await _productService.UpdateProductAsync(id, updateDto);

            _logger.LogInformation("Product updated by admin: {ProductId}", id);

            return Ok(product);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating product: {ProductId}", id);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Xóa sản phẩm (chỉ admin)
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Delete(string id)
    {
        try
        {
            await _productService.DeleteProductAsync(id);

            _logger.LogInformation("Product deleted by admin: {ProductId}", id);

            return Ok(new { message = "Product deleted successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting product: {ProductId}", id);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Khôi phục sản phẩm đã xóa (chỉ admin)
    /// </summary>
    [HttpPatch("{id}/restore")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Restore(string id)
    {
        try
        {
            await _productService.RestoreProductAsync(id);

            _logger.LogInformation("Product restored by admin: {ProductId}", id);

            return Ok(new { message = "Product restored successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error restoring product: {ProductId}", id);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Cập nhật số lượng tồn kho (chỉ admin)
    /// </summary>
    [HttpPatch("{id}/stock")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> UpdateStock(string id, [FromBody] int quantity)
    {
        try
        {
            await _productService.UpdateStockAsync(id, quantity);

            _logger.LogInformation("Product stock updated by admin: {ProductId} - New stock: {Quantity}", id, quantity);

            return Ok(new { message = "Stock updated successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating stock for product: {ProductId}", id);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Kiểm tra sản phẩm còn hàng không
    /// </summary>
    [HttpGet("{id}/instock")]
    public async Task<IActionResult> CheckInStock(string id, [FromQuery] int quantity = 1)
    {
        try
        {
            var inStock = await _productService.IsInStockAsync(id, quantity);
            return Ok(new
            {
                productId = id,
                inStock = inStock,
                message = inStock ? "Product is in stock" : "Product is out of stock"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking stock for product: {ProductId}", id);
            return StatusCode(500, new { message = "An error occurred while checking stock" });
        }
    }
}
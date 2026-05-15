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
            _logger.LogError(ex, "Lỗi khi lấy danh sách sản phẩm");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi lấy danh sách sản phẩm" });
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
            _logger.LogError(ex, "Lỗi khi tìm kiếm sản phẩm");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi tìm kiếm sản phẩm" });
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
            _logger.LogError(ex, "Lỗi khi lấy sản phẩm theo danh mục");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi lấy sản phẩm theo danh mục" });
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
                return NotFound(new { message = $"Không tìm thấy sản phẩm với ID {id}" });

            return Ok(product);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi lấy sản phẩm theo ID: {ProductId}", id);
            return StatusCode(500, new { message = "Có lỗi xảy ra khi lấy thông tin sản phẩm" });
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
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var product = await _productService.CreateProductAsync(createDto);

            _logger.LogInformation("Admin đã tạo sản phẩm: {ProductId}", product.ProductId);

            return CreatedAtAction(nameof(GetById), new { id = product.ProductId }, product);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi tạo sản phẩm");
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
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var product = await _productService.UpdateProductAsync(id, updateDto);

            _logger.LogInformation("Admin đã cập nhật sản phẩm: {ProductId}", id);

            return Ok(product);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi cập nhật sản phẩm: {ProductId}", id);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Xóa sản phẩm (chỉ admin) - Chỉ xóa được sản phẩm chưa có đơn hàng
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Delete(string id)
    {
        try
        {
            await _productService.DeleteProductAsync(id);
            _logger.LogInformation("Admin đã xóa sản phẩm: {ProductId}", id);
            return Ok(new { message = "Xóa sản phẩm thành công" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi xóa sản phẩm: {ProductId}", id);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Cập nhật trạng thái kinh doanh của sản phẩm (chỉ admin)
    /// </summary>
    [HttpPatch("{id}/active")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> SetActive(string id, [FromBody] bool isActive)
    {
        try
        {
            await _productService.UpdateProductStatusAsync(id, isActive);
            var trangThai = isActive ? "kích hoạt" : "ngừng kinh doanh";
            return Ok(new { id, isActive, message = $"Đã {trangThai} sản phẩm" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi cập nhật trạng thái sản phẩm: {ProductId}", id);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Khôi phục sản phẩm đã ngừng kinh doanh (chỉ admin)
    /// </summary>
    [HttpPatch("{id}/restore")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Restore(string id)
    {
        try
        {
            await _productService.RestoreProductAsync(id);
            _logger.LogInformation("Admin đã khôi phục sản phẩm: {ProductId}", id);
            return Ok(new { message = "Khôi phục sản phẩm thành công" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi khôi phục sản phẩm: {ProductId}", id);
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
            _logger.LogInformation("Admin đã cập nhật tồn kho sản phẩm: {ProductId} - Tồn mới: {Quantity}", id, quantity);
            return Ok(new { message = "Cập nhật tồn kho thành công" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi cập nhật tồn kho sản phẩm: {ProductId}", id);
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
                message = inStock ? "Sản phẩm còn hàng" : "Sản phẩm đã hết hàng"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi kiểm tra tồn kho sản phẩm: {ProductId}", id);
            return StatusCode(500, new { message = "Có lỗi xảy ra khi kiểm tra tồn kho" });
        }
    }
}
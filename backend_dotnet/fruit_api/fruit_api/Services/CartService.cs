using Microsoft.EntityFrameworkCore;
using fruit_api.Data;
using fruit_api.DTOs.Cart;
using fruit_api.Models;
using fruit_api.Services.Interfaces;

namespace fruit_api.Services;

public class CartService : ICartService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<CartService> _logger;

    public CartService(ApplicationDbContext context, ILogger<CartService> logger)
    {
        _context = context;
        _logger = logger;
    }

    // ===============================
    // Generate CartId: CT0001, CT0002...
    // ===============================
    private async Task<string> GenerateCartId()
    {
        var lastCart = await _context.Carts
            .OrderByDescending(c => c.CartId)
            .FirstOrDefaultAsync();

        int nextNumber = 1;

        if (lastCart != null && !string.IsNullOrEmpty(lastCart.CartId) && lastCart.CartId.Length >= 6)
        {
            string numberPart = lastCart.CartId.Substring(2);
            if (int.TryParse(numberPart, out int lastNumber))
            {
                nextNumber = lastNumber + 1;
            }
        }

        return "CT" + nextNumber.ToString("D4");
    }

    private async Task<string> GenerateCartItemId()
    {
        var lastItem = await _context.CartItems
            .OrderByDescending(ci => ci.CartItemId)
            .FirstOrDefaultAsync();

        int nextNumber = 1;

        if (lastItem != null && !string.IsNullOrEmpty(lastItem.CartItemId) && lastItem.CartItemId.Length >= 6)
        {
            string numberPart = lastItem.CartItemId.Substring(2);
            if (int.TryParse(numberPart, out int lastNumber))
            {
                nextNumber = lastNumber + 1;
            }
        }

        return "CI" + nextNumber.ToString("D4");
    }

    private async Task<Cart> GetOrCreateCartAsync(string userId)
    {
        var cart = await _context.Carts
            .Include(c => c.CartItems)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart == null)
        {
            _logger.LogInformation("Cart not found, creating new cart for user: {UserId}", userId);

            cart = new Cart
            {
                CartId = await GenerateCartId(),
                UserId = userId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Carts.Add(cart);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Created new cart: {CartId} for user: {UserId}", cart.CartId, userId);
        }

        return cart;
    }

    // ===============================
    // Get Cart - Lấy stock real-time từ Products
    // ===============================
    public async Task<CartDto> GetCartAsync(string userId)
    {
        try
        {
            _logger.LogInformation("Getting cart for user: {UserId}", userId);

            var cart = await _context.Carts
                .Include(c => c.CartItems!)
                    .ThenInclude(ci => ci.Product)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null)
            {
                _logger.LogWarning("Cart not found for user: {UserId}", userId);

                // Tạo cart mới nếu chưa có
                cart = await GetOrCreateCartAsync(userId);
            }

            var cartDto = new CartDto
            {
                CartId = cart.CartId,
                UserId = cart.UserId,
                UpdatedAt = cart.UpdatedAt,
                Items = cart.CartItems?.Select(ci => new CartItemDto
                {
                    CartItemId = ci.CartItemId,
                    ProductId = ci.ProductId,
                    ProductName = ci.Product?.ProductName ?? string.Empty,
                    ImageUrl = ci.Product?.ImageUrl,
                    Unit = ci.Product?.Unit ?? string.Empty,
                    stockQuantity = ci.Product?.StockQuantity ?? 0, // ✅ Stock real-time từ Product
                    Price = ci.Product?.Price ?? ci.PriceAtTime,    // ✅ Giá real-time từ Product
                    Quantity = ci.Quantity,
                    Subtotal = ci.Quantity * (ci.Product?.Price ?? ci.PriceAtTime)
                }).ToList() ?? new List<CartItemDto>(),
                TotalItems = cart.CartItems?.Sum(ci => ci.Quantity) ?? 0,
                TotalPrice = cart.CartItems?.Sum(ci => ci.Quantity * (ci.Product?.Price ?? ci.PriceAtTime)) ?? 0
            };

            return cartDto;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting cart for user: {UserId}", userId);
            throw new Exception($"Error getting cart: {ex.Message}");
        }
    }

    // ===============================
    // Get Cart with Auto-Correct - Tự động điều chỉnh số lượng nếu vượt stock
    // ===============================
    public async Task<CartDto> GetCartWithAutoCorrectAsync(string userId)
    {
        try
        {
            _logger.LogInformation("Getting cart with auto-correct for user: {UserId}", userId);

            var cart = await _context.Carts
                .Include(c => c.CartItems!)
                    .ThenInclude(ci => ci.Product)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null)
            {
                cart = await GetOrCreateCartAsync(userId);
                return await GetCartAsync(userId);
            }

            bool hasChanges = false;

            // Kiểm tra và tự động điều chỉnh số lượng nếu vượt stock
            foreach (var item in cart.CartItems ?? new List<CartItem>())
            {
                if (item.Product != null && item.Quantity > item.Product.StockQuantity)
                {
                    var oldQuantity = item.Quantity;
                    var newQuantity = item.Product.StockQuantity;

                    item.Quantity = newQuantity;
                    hasChanges = true;

                    _logger.LogInformation(
                        "Auto-corrected cart item {CartItemId}: quantity from {OldQuantity} to {NewQuantity} (stock: {Stock}, product: {ProductName})",
                        item.CartItemId, oldQuantity, newQuantity, item.Product.StockQuantity, item.Product.ProductName);
                }
            }

            if (hasChanges)
            {
                cart.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            var cartDto = new CartDto
            {
                CartId = cart.CartId,
                UserId = cart.UserId,
                UpdatedAt = cart.UpdatedAt,
                Items = cart.CartItems?.Select(ci => new CartItemDto
                {
                    CartItemId = ci.CartItemId,
                    ProductId = ci.ProductId,
                    ProductName = ci.Product?.ProductName ?? string.Empty,
                    ImageUrl = ci.Product?.ImageUrl,
                    Unit = ci.Product?.Unit ?? string.Empty,
                    stockQuantity = ci.Product?.StockQuantity ?? 0,
                    Price = ci.Product?.Price ?? ci.PriceAtTime,
                    Quantity = ci.Quantity,
                    Subtotal = ci.Quantity * (ci.Product?.Price ?? ci.PriceAtTime)
                }).ToList() ?? new List<CartItemDto>(),
                TotalItems = cart.CartItems?.Sum(ci => ci.Quantity) ?? 0,
                TotalPrice = cart.CartItems?.Sum(ci => ci.Quantity * (ci.Product?.Price ?? ci.PriceAtTime)) ?? 0,
                HasAutoCorrected = hasChanges  // ✅ Thêm flag để frontend biết
            };

            return cartDto;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting cart with auto-correct for user: {UserId}", userId);
            throw new Exception($"Error getting cart: {ex.Message}");
        }
    }

    // ===============================
    // Add product to cart - Đã sửa kiểm tra stock chính xác
    // ===============================
    public async Task<CartDto> AddToCartAsync(string userId, AddToCartDto addToCartDto)
    {
        try
        {
            _logger.LogInformation("Adding to cart - User: {UserId}, Product: {ProductId}, Quantity: {Quantity}",
                userId, addToCartDto.ProductId, addToCartDto.Quantity);

            // Validate input
            if (addToCartDto.Quantity <= 0)
                throw new Exception("Số lượng phải lớn hơn 0");

            if (string.IsNullOrEmpty(addToCartDto.ProductId))
                throw new Exception("Product ID is required");

            // Get or create cart
            var cart = await GetOrCreateCartAsync(userId);

            // Check product exists and get latest stock
            var product = await _context.Products
                .FirstOrDefaultAsync(p => p.ProductId == addToCartDto.ProductId);

            if (product == null)
            {
                _logger.LogWarning("Product not found: {ProductId}", addToCartDto.ProductId);
                throw new Exception($"Sản phẩm với ID {addToCartDto.ProductId} không tồn tại");
            }

            if (!product.IsActive)
            {
                _logger.LogWarning("Product is not active: {ProductId}", addToCartDto.ProductId);
                throw new Exception("Sản phẩm hiện không khả dụng");
            }

            // Check if product already in cart
            var existingItem = cart.CartItems?
                .FirstOrDefault(ci => ci.ProductId == addToCartDto.ProductId);

            int currentQuantity = existingItem?.Quantity ?? 0;
            int totalQuantity = currentQuantity + addToCartDto.Quantity;

            // ✅ TÍNH SỐ LƯỢNG TỐI ĐA CÓ THỂ THÊM
            int maxAddable = product.StockQuantity - currentQuantity;

            if (maxAddable <= 0)
            {
                throw new Exception($"Bạn đã có {currentQuantity} sản phẩm trong giỏ. Không thể thêm sản phẩm này nữa vì đã đạt tối đa tồn kho ({product.StockQuantity}).");
            }

            if (addToCartDto.Quantity > maxAddable)
            {
                throw new Exception($"Bạn chỉ có thể thêm tối đa {maxAddable} sản phẩm nữa. Hiện tại bạn đã có {currentQuantity} sản phẩm, tồn kho còn {product.StockQuantity}.");
            }

            if (totalQuantity > product.StockQuantity)
            {
                throw new Exception($"Không thể thêm {addToCartDto.Quantity} sản phẩm. Bạn đã có {currentQuantity} trong giỏ, tồn kho chỉ còn {product.StockQuantity}. Bạn chỉ có thể thêm tối đa {maxAddable} sản phẩm.");
            }

            // Update or create cart item
            if (existingItem != null)
            {
                existingItem.Quantity = totalQuantity;
                existingItem.PriceAtTime = product.Price;
                _logger.LogInformation("Updated existing cart item. New quantity: {Quantity}", totalQuantity);
            }
            else
            {
                string cartItemId = await GenerateCartItemId();
                var cartItem = new CartItem
                {
                    CartItemId = cartItemId,
                    CartId = cart.CartId,
                    ProductId = addToCartDto.ProductId,
                    Quantity = totalQuantity,
                    PriceAtTime = product.Price
                };
                _context.CartItems.Add(cartItem);
                _logger.LogInformation("Created new cart item with ID: {CartItemId}", cartItemId);
            }

            cart.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Successfully added to cart. User: {UserId}, Product: {ProductId}, Final quantity: {FinalQuantity}",
                userId, addToCartDto.ProductId, totalQuantity);

            return await GetCartAsync(userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding to cart for user: {UserId}", userId);
            throw;
        }
    }

    // ===============================
    // Update item in cart - Đã sửa kiểm tra stock
    // ===============================
    public async Task<CartDto> UpdateCartItemAsync(string userId, string productId, UpdateCartItemDto updateDto)
    {
        try
        {
            _logger.LogInformation("Updating cart item - User: {UserId}, Product: {ProductId}, New Quantity: {Quantity}",
                userId, productId, updateDto.Quantity);

            if (string.IsNullOrEmpty(productId))
                throw new Exception("Product ID is required");

            var cart = await _context.Carts
                .Include(c => c.CartItems)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null)
            {
                _logger.LogWarning("Cart not found for user: {UserId}", userId);
                throw new Exception("Cart not found");
            }

            var cartItem = await _context.CartItems
                .Include(ci => ci.Product)
                .FirstOrDefaultAsync(ci => ci.CartId == cart.CartId && ci.ProductId == productId);

            if (cartItem == null)
            {
                _logger.LogWarning("Item not found in cart. User: {UserId}, Product: {ProductId}", userId, productId);
                throw new Exception("Item not found in cart");
            }

            if (updateDto.Quantity <= 0)
            {
                _logger.LogInformation("Removing item from cart. User: {UserId}, Product: {ProductId}", userId, productId);
                _context.CartItems.Remove(cartItem);
            }
            else
            {
                var product = cartItem.Product ?? await _context.Products.FindAsync(productId);
                if (product == null)
                {
                    _logger.LogWarning("Product not found: {ProductId}", productId);
                    throw new Exception("Product not found");
                }

                // ✅ Kiểm tra stock
                if (product.StockQuantity < updateDto.Quantity)
                {
                    _logger.LogWarning("Not enough stock. Product: {ProductId}, Requested: {Requested}, Available: {Available}",
                        productId, updateDto.Quantity, product.StockQuantity);

                    // Gợi ý số lượng tối đa có thể đặt
                    throw new Exception($"Chỉ còn {product.StockQuantity} sản phẩm trong kho. Bạn có thể đặt tối đa {product.StockQuantity} sản phẩm.");
                }

                cartItem.Quantity = updateDto.Quantity;
            }

            cart.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Successfully updated cart item. User: {UserId}, Product: {ProductId}", userId, productId);

            return await GetCartAsync(userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating cart item for user: {UserId}", userId);
            throw;
        }
    }

    // ===============================
    // Remove item from cart
    // ===============================
    public async Task<bool> RemoveFromCartAsync(string userId, string productId)
    {
        try
        {
            _logger.LogInformation("Removing from cart - User: {UserId}, Product: {ProductId}", userId, productId);

            if (string.IsNullOrEmpty(productId))
                throw new Exception("Product ID is required");

            var cart = await _context.Carts
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null)
            {
                _logger.LogWarning("Cart not found for user: {UserId}", userId);
                throw new Exception("Cart not found");
            }

            var cartItem = await _context.CartItems
                .FirstOrDefaultAsync(ci => ci.CartId == cart.CartId && ci.ProductId == productId);

            if (cartItem == null)
            {
                _logger.LogWarning("Item not found in cart. User: {UserId}, Product: {ProductId}", userId, productId);
                throw new Exception("Item not found in cart");
            }

            _context.CartItems.Remove(cartItem);
            cart.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Successfully removed from cart. User: {UserId}, Product: {ProductId}", userId, productId);

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error removing from cart for user: {UserId}", userId);
            throw;
        }
    }

    // ===============================
    // Clear cart
    // ===============================
    public async Task<bool> ClearCartAsync(string userId)
    {
        try
        {
            _logger.LogInformation("Clearing cart for user: {UserId}", userId);

            var cart = await _context.Carts
                .Include(c => c.CartItems)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null)
            {
                _logger.LogWarning("Cart not found for user: {UserId}", userId);
                throw new Exception("Cart not found");
            }

            if (cart.CartItems != null && cart.CartItems.Any())
            {
                _context.CartItems.RemoveRange(cart.CartItems);
            }

            cart.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Successfully cleared cart for user: {UserId}", userId);

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error clearing cart for user: {UserId}", userId);
            throw;
        }
    }
}
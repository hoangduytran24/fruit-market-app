using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using fruit_api.DTOs.Cart;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class CartController : ControllerBase
{
    private readonly ICartService _cartService;

    public CartController(ICartService cartService)
    {
        _cartService = cartService;
    }

    private string GetUserId()
    {
        return User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();
    }

    [HttpGet]
    public async Task<IActionResult> GetCart()
    {
        try
        {
            var userId = GetUserId();
            var cart = await _cartService.GetCartAsync(userId);
            return Ok(cart);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("add")]
    public async Task<IActionResult> AddToCart(AddToCartDto addToCartDto)
    {
        try
        {
            var userId = GetUserId();
            var cart = await _cartService.AddToCartAsync(userId, addToCartDto);
            return Ok(cart);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("update/{productId}")]
    public async Task<IActionResult> UpdateCartItem(string productId, UpdateCartItemDto updateDto)
    {
        try
        {
            var userId = GetUserId();
            var cart = await _cartService.UpdateCartItemAsync(userId, productId, updateDto);
            return Ok(cart);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("remove/{productId}")]
    public async Task<IActionResult> RemoveFromCart(string productId)
    {
        try
        {
            var userId = GetUserId();
            await _cartService.RemoveFromCartAsync(userId, productId);
            return Ok(new { message = "Item removed from cart" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("clear")]
    public async Task<IActionResult> ClearCart()
    {
        try
        {
            var userId = GetUserId();
            await _cartService.ClearCartAsync(userId);
            return Ok(new { message = "Cart cleared" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
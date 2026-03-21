using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using fruit_api.DTOs.Order;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;

    public OrdersController(IOrderService orderService)
    {
        _orderService = orderService;
    }

    private string GetUserId()
    {
        return User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();
    }

    private string GetUserRole()
    {
        return User.FindFirst(ClaimTypes.Role)?.Value ?? "user";
    }

    [HttpGet]
    public async Task<IActionResult> GetMyOrders()
    {
        try
        {
            var userId = GetUserId();
            var orders = await _orderService.GetUserOrdersAsync(userId);
            return Ok(orders);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("admin/all")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> GetAllOrders([FromQuery] string? status = null)
    {
        try
        {
            var orders = await _orderService.GetAllOrdersAsync(status);
            return Ok(orders);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetOrderById(string id)
    {
        try
        {
            var order = await _orderService.GetOrderByIdAsync(id);
            if (order == null)
                return NotFound(new { message = "Order not found" });

            // Check if user owns this order or is admin
            var userId = GetUserId();
            var userRole = GetUserRole();

            if (order.UserId != userId && userRole != "admin")
                return Forbid();

            return Ok(order);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<IActionResult> CreateOrder(CreateOrderDto createOrderDto)
    {
        try
        {
            var userId = GetUserId();
            var order = await _orderService.CreateOrderAsync(userId, createOrderDto);
            return Ok(order);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("buy-now")]
    public async Task<IActionResult> BuyNow([FromBody] BuyNowDto buyNowDto)
    {
        try
        {
            var userId = GetUserId();
            var order = await _orderService.BuyNowAsync(userId, buyNowDto);
            return Ok(order);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{id}/status")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> UpdateOrderStatus(string id, UpdateOrderStatusDto updateDto)
    {
        try
        {
            var order = await _orderService.UpdateOrderStatusAsync(id, updateDto);
            return Ok(order);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id}/cancel")]
    public async Task<IActionResult> CancelOrder(string id)
    {
        try
        {
            var userId = GetUserId();
            var order = await _orderService.GetOrderByIdAsync(id);

            if (order == null)
                return NotFound(new { message = "Order not found" });

            // Check if user owns this order
            if (order.UserId != userId)
                return Forbid();

            await _orderService.CancelOrderAsync(id);
            return Ok(new { message = "Order cancelled successfully" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
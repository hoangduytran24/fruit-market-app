using Microsoft.AspNetCore.Mvc;
using fruit_api.DTOs.Inventory;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class InventoryController : ControllerBase
{
    private readonly IInventoryService _inventoryService;

    public InventoryController(IInventoryService inventoryService)
    {
        _inventoryService = inventoryService;
    }

    // GET: api/inventory
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var inventories = await _inventoryService.GetAllInventoriesAsync();
        return Ok(inventories);
    }

    // GET: api/inventory/{id}
    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        var inventory = await _inventoryService.GetInventoryByIdAsync(id);
        if (inventory == null)
            return NotFound();
        return Ok(inventory);
    }

    //GET: api/inventory/expiring?days=7
    [HttpGet("expiring")]
    public async Task<IActionResult> GetExpiring([FromQuery] int days = 7)
    {
        try
        {
            var inventories = await _inventoryService.GetExpiringInventoriesAsync(days);
            return Ok(inventories);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    //GET: api/inventory/expired
    [HttpGet("expired")]
    public async Task<IActionResult> GetExpired()
    {
        try
        {
            var inventories = await _inventoryService.GetExpiredInventoriesAsync();
            return Ok(inventories);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // POST: api/inventory (Nhập hàng mới)
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateInventoryDto createDto)
    {
        try
        {
            var inventory = await _inventoryService.CreateInventoryAsync(createDto);
            return Ok(inventory);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // PUT: api/inventory/{id}
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] UpdateInventoryDto updateDto)
    {
        try
        {
            var inventory = await _inventoryService.UpdateInventoryAsync(id, updateDto);
            return Ok(inventory);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // DELETE: api/inventory/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        try
        {
            var result = await _inventoryService.DeleteInventoryAsync(id);
            return Ok(new { success = result });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
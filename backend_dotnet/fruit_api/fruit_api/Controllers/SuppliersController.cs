using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using fruit_api.DTOs.Supplier;
using fruit_api.Services.Interfaces;

namespace fruit_api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class SuppliersController : ControllerBase
{
    private readonly ISupplierService _supplierService;

    public SuppliersController(ISupplierService supplierService)
    {
        _supplierService = supplierService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var suppliers = await _supplierService.GetAllSuppliersAsync();
        return Ok(suppliers);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        var supplier = await _supplierService.GetSupplierByIdAsync(id);
        if (supplier == null)
            return NotFound(new { message = "Supplier not found" });

        return Ok(supplier);
    }

    [HttpPost]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Create(CreateSupplierDto createDto)
    {
        try
        {
            var supplier = await _supplierService.CreateSupplierAsync(createDto);
            return CreatedAtAction(nameof(GetById), new { id = supplier.SupplierId }, supplier);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Update(string id, UpdateSupplierDto updateDto)
    {
        try
        {
            var supplier = await _supplierService.UpdateSupplierAsync(id, updateDto);
            return Ok(supplier);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> Delete(string id)
    {
        try
        {
            await _supplierService.DeleteSupplierAsync(id);
            return NoContent();
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using fruit_api.Services.Interfaces;
using fruit_api.DTOs.Upload;

namespace fruit_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class UploadController : ControllerBase
{
    private readonly IFileService _fileService;

    public UploadController(IFileService fileService)
    {
        _fileService = fileService;
    }

    [HttpPost("image/{folder?}")]
    [RequestSizeLimit(10 * 1024 * 1024)] // 10MB max
    public async Task<IActionResult> UploadImage(IFormFile file, string folder = "products")
    {
        try
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "No file uploaded" });

            var result = await _fileService.UploadImageAsync(file, folder);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("images/{folder?}")]
    [RequestSizeLimit(50 * 1024 * 1024)] // 50MB max
    public async Task<IActionResult> UploadMultipleImages(IFormFileCollection files, string folder = "products")
    {
        try
        {
            if (files == null || files.Count == 0)
                return BadRequest(new { message = "No files uploaded" });

            var result = await _fileService.UploadMultipleImagesAsync(files, folder);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("image")]
    public async Task<IActionResult> DeleteImage([FromQuery] string filePath)
    {
        try
        {
            var result = await _fileService.DeleteImageAsync(filePath);
            if (result)
                return Ok(new { message = "File deleted successfully" });
            
            return NotFound(new { message = "File not found" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
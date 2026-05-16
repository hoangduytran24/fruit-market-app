using Microsoft.AspNetCore.Http;

namespace fruit_api.Services.Interfaces;

public interface IFileUploadService
{
    Task<string> UploadImageAsync(IFormFile file, string folder);
    Task<bool> DeleteImageAsync(string imageUrl);
}
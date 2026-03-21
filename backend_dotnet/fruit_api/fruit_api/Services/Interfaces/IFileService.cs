using Microsoft.AspNetCore.Http;
using fruit_api.DTOs.Upload;

namespace fruit_api.Services.Interfaces;

public interface IFileService
{
    Task<UploadResultDto> UploadImageAsync(IFormFile file, string folder = "products");
    Task<UploadMultipleResultDto> UploadMultipleImagesAsync(IFormFileCollection files, string folder = "products");
    Task<bool> DeleteImageAsync(string filePath);
    Task<string> GetImageUrl(string fileName, string folder = "products");
    bool IsImageFile(string fileName);
    bool IsValidImageSize(long fileSize, long maxSizeInMB = 5);
}
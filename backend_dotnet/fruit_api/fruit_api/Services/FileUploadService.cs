using Microsoft.AspNetCore.Http;
using fruit_api.Services.Interfaces;

namespace fruit_api.Services;

public class FileUploadService : IFileUploadService
{
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<FileUploadService> _logger;

    public FileUploadService(IWebHostEnvironment environment, ILogger<FileUploadService> logger)
    {
        _environment = environment;
        _logger = logger;
    }

    public async Task<string> UploadImageAsync(IFormFile file, string folder)
    {
        try
        {
            if (file == null || file.Length == 0)
                throw new Exception("Không có file nào được chọn");

            // Kiểm tra định dạng file
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
            var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!allowedExtensions.Contains(fileExtension))
                throw new Exception("Định dạng file không hợp lệ. Chỉ chấp nhận: jpg, jpeg, png, gif, webp");

            // Kiểm tra kích thước (max 5MB)
            if (file.Length > 5 * 1024 * 1024)
                throw new Exception("File quá lớn. Kích thước tối đa 5MB");

            // Tạo tên file duy nhất
            var fileName = $"{Guid.NewGuid()}{fileExtension}";
            var uploadPath = Path.Combine(_environment.WebRootPath ?? "wwwroot", "uploads", folder);

            // Tạo thư mục nếu chưa tồn tại
            if (!Directory.Exists(uploadPath))
                Directory.CreateDirectory(uploadPath);

            var filePath = Path.Combine(uploadPath, fileName);

            // Lưu file
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Trả về URL
            return $"/uploads/{folder}/{fileName}";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi upload ảnh");
            throw;
        }
    }

    public async Task<bool> DeleteImageAsync(string imageUrl)
    {
        try
        {
            if (string.IsNullOrEmpty(imageUrl)) return true;

            var relativePath = imageUrl.Replace("/", Path.DirectorySeparatorChar.ToString())
                                        .TrimStart(Path.DirectorySeparatorChar);
            var fullPath = Path.Combine(_environment.WebRootPath ?? "wwwroot", relativePath);

            if (File.Exists(fullPath))
            {
                await Task.Run(() => File.Delete(fullPath));
            }
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi xóa ảnh");
            return false;
        }
    }
}
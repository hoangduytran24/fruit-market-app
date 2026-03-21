using fruit_api.DTOs.Upload;
using fruit_api.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace fruit_api.Services;

public class FileService : IFileService
{
    private readonly IWebHostEnvironment _environment;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IConfiguration _configuration;
    private readonly string[] _allowedExtensions;
    private readonly int _maxFileSizeMB;

    public FileService(IWebHostEnvironment environment, IHttpContextAccessor httpContextAccessor, IConfiguration configuration)
    {
        _environment = environment;
        _httpContextAccessor = httpContextAccessor;
        _configuration = configuration;
        _allowedExtensions = _configuration.GetSection("FileSettings:AllowedExtensions").Get<string[]>()
            ?? new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
        _maxFileSizeMB = _configuration.GetValue<int>("FileSettings:MaxFileSizeMB", 5);
    }

    public async Task<UploadResultDto> UploadImageAsync(IFormFile file, string folder = "products")
    {
        if (file == null || file.Length == 0)
            throw new Exception("No file uploaded");

        // Kiểm tra file có phải là ảnh không
        if (!IsImageFile(file.FileName))
            throw new Exception("Invalid file format. Only images are allowed (jpg, jpeg, png, gif, webp)");

        // Kiểm tra kích thước file
        if (!IsValidImageSize(file.Length))
            throw new Exception($"File size exceeds {_maxFileSizeMB}MB limit");

        // Tạo tên file duy nhất
        var fileName = GenerateUniqueFileName(file.FileName);

        // Tạo đường dẫn thư mục
        var uploadFolder = Path.Combine("images", folder);
        var folderPath = Path.Combine(_environment.WebRootPath, uploadFolder);

        // Tạo thư mục nếu chưa tồn tại
        if (!Directory.Exists(folderPath))
        {
            Directory.CreateDirectory(folderPath);
        }

        // Đường dẫn đầy đủ của file
        var filePath = Path.Combine(folderPath, fileName);

        // Lưu file
        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        // Tối ưu ảnh (resize nếu cần)
        await OptimizeImageAsync(filePath);

        // Tạo URL để truy cập ảnh
        var fileUrl = await GetImageUrl(fileName, folder);

        return new UploadResultDto
        {
            FileName = fileName,
            FilePath = Path.Combine(uploadFolder, fileName).Replace("\\", "/"),
            FileUrl = fileUrl,
            FileSize = file.Length,
            ContentType = file.ContentType,
            UploadedAt = DateTime.Now
        };
    }

    public async Task<UploadMultipleResultDto> UploadMultipleImagesAsync(IFormFileCollection files, string folder = "products")
    {
        var result = new UploadMultipleResultDto();

        foreach (var file in files)
        {
            try
            {
                var uploadResult = await UploadImageAsync(file, folder);
                result.SuccessfulUploads.Add(uploadResult);
                result.TotalUploaded++;
            }
            catch (Exception)
            {
                result.FailedFiles.Add(file.FileName);
            }
        }

        return result;
    }

    public async Task<bool> DeleteImageAsync(string filePath)
    {
        try
        {
            var fullPath = Path.Combine(_environment.WebRootPath, filePath.TrimStart('/').Replace("/", "\\"));

            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
                return true;
            }

            return false;
        }
        catch (Exception)
        {
            return false;
        }
    }

    public async Task<string> GetImageUrl(string fileName, string folder = "products")
    {
        var request = _httpContextAccessor.HttpContext?.Request;
        var baseUrl = $"{request?.Scheme}://{request?.Host}";
        var imageUrl = $"{baseUrl}/images/{folder}/{fileName}";

        return await Task.FromResult(imageUrl);
    }

    public bool IsImageFile(string fileName)
    {
        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        return _allowedExtensions.Contains(extension);
    }

    public bool IsValidImageSize(long fileSize, long maxSizeInMB = 5)
    {
        var maxSizeInBytes = maxSizeInMB * 1024 * 1024;
        return fileSize <= maxSizeInBytes;
    }

    private string GenerateUniqueFileName(string originalFileName)
    {
        var extension = Path.GetExtension(originalFileName);
        var fileNameWithoutExt = Path.GetFileNameWithoutExtension(originalFileName);
        var timestamp = DateTime.Now.ToString("yyyyMMddHHmmss");
        var guid = Guid.NewGuid().ToString("N").Substring(0, 8);

        // Loại bỏ ký tự đặc biệt và khoảng trắng
        var safeName = string.Join("_", fileNameWithoutExt.Split(Path.GetInvalidFileNameChars()));

        return $"{safeName}_{timestamp}_{guid}{extension}";
    }

    private async Task OptimizeImageAsync(string filePath)
    {
        try
        {
            using var image = await Image.LoadAsync(filePath);

            // Resize nếu ảnh quá lớn (giữ tỷ lệ)
            if (image.Width > 1920 || image.Height > 1080)
            {
                image.Mutate(x => x.Resize(new ResizeOptions
                {
                    Mode = ResizeMode.Max,
                    Size = new Size(1920, 1080)
                }));

                await image.SaveAsync(filePath);
            }
        }
        catch (Exception)
        {
            // Bỏ qua nếu không optimize được
        }
    }
}
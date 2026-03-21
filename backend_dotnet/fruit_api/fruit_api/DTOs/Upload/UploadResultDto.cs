namespace fruit_api.DTOs.Upload;

public class UploadResultDto
{
    public string FileName { get; set; } = string.Empty;
    public string FilePath { get; set; } = string.Empty;
    public string FileUrl { get; set; } = string.Empty;
    public long FileSize { get; set; }
    public string ContentType { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; }
}

public class UploadMultipleResultDto
{
    public List<UploadResultDto> SuccessfulUploads { get; set; } = new();
    public List<string> FailedFiles { get; set; } = new();
    public int TotalUploaded { get; set; }
}
namespace fruit_api.DTOs.Review;

public class ReviewDto
{
    public string ReviewId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateReviewDto
{
    public string ProductId { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string? Comment { get; set; }
}
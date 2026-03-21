namespace fruit_api.DTOs.Favorites
{
    public class FavoriteDto
    {
        public string FavoriteId { get; set; } = string.Empty;
        public string ProductId { get; set; } = string.Empty;
        public string ProductName { get; set; } = string.Empty;
        public string ProductImage { get; set; } = string.Empty;
        public decimal ProductPrice { get; set; }
        public string ProductUnit { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }

    public class CreateFavoriteDto
    {
        public string ProductId { get; set; } = string.Empty;
    }

    public class FavoriteListResponseDto
    {
        public int TotalCount { get; set; }
        public List<FavoriteDto> Items { get; set; } = new();
    }
}
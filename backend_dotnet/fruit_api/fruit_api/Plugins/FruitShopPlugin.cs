using System.ComponentModel;
using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.SemanticKernel;

namespace fruit_api.Plugins;  

public class FruitShopPlugin
{
    private readonly string _connectionString;

    public FruitShopPlugin(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new Exception("Connection string not found");
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    // ==================== SẢN PHẨM ====================

    [KernelFunction("get_discounted_products")]
    [Description("Lấy danh sách sản phẩm đang giảm giá")]
    public async Task<List<ProductInfo>> GetDiscountedProductsAsync()
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT p.productId, p.productName, p.price, p.unit, p.stockQuantity,
                   c.categoryName, s.supplierName
            FROM Products p
            LEFT JOIN Categories c ON p.categoryId = c.categoryId
            LEFT JOIN Suppliers s ON p.supplierId = s.supplierId
            WHERE p.isActive = 1
            ORDER BY p.createdAt DESC";

        var products = await connection.QueryAsync<ProductInfo>(sql);
        return products.Take(5).ToList();
    }

    [KernelFunction("search_products")]
    [Description("Tìm kiếm sản phẩm theo từ khóa")]
    public async Task<List<ProductInfo>> SearchProductsAsync(
        [Description("Từ khóa tìm kiếm sản phẩm")] string keyword)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT p.productId, p.productName, p.price, p.unit, p.stockQuantity,
                   c.categoryName, s.supplierName
            FROM Products p
            LEFT JOIN Categories c ON p.categoryId = c.categoryId
            LEFT JOIN Suppliers s ON p.supplierId = s.supplierId
            WHERE p.isActive = 1 AND p.productName LIKE @Keyword";

        var products = await connection.QueryAsync<ProductInfo>(sql, new { Keyword = $"%{keyword}%" });
        return products.ToList();
    }

    [KernelFunction("get_product_detail")]
    [Description("Lấy chi tiết sản phẩm theo ID")]
    public async Task<ProductDetail?> GetProductDetailAsync(
        [Description("ID sản phẩm")] string productId)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT p.productId, p.productName, p.price, p.unit, p.stockQuantity, p.description,
                   c.categoryName, s.supplierName, s.phone as supplierPhone
            FROM Products p
            LEFT JOIN Categories c ON p.categoryId = c.categoryId
            LEFT JOIN Suppliers s ON p.supplierId = s.supplierId
            WHERE p.productId = @ProductId AND p.isActive = 1";

        return await connection.QueryFirstOrDefaultAsync<ProductDetail>(sql, new { ProductId = productId });
    }

    // ==================== ĐƠN HÀNG ====================

    [KernelFunction("check_order")]
    [Description("Kiểm tra thông tin đơn hàng theo mã đơn")]
    public async Task<OrderInfo?> CheckOrderAsync(
        [Description("Mã đơn hàng")] string orderCode)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT orderId, userId, totalAmount, discountAmount, finalAmount, 
                   status, paymentMethod, deliveryAddress, createdAt
            FROM Orders 
            WHERE orderId = @OrderCode";

        return await connection.QueryFirstOrDefaultAsync<OrderInfo>(sql, new { OrderCode = orderCode });
    }

    [KernelFunction("get_orders_by_phone")]
    [Description("Lấy danh sách đơn hàng theo số điện thoại")]
    public async Task<List<OrderInfo>> GetOrdersByPhoneAsync(
        [Description("Số điện thoại khách hàng")] string phone)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT o.orderId, o.userId, o.totalAmount, o.discountAmount, o.finalAmount, 
                   o.status, o.paymentMethod, o.deliveryAddress, o.createdAt,
                   u.phone, u.fullName
            FROM Orders o
            JOIN Users u ON o.userId = u.userId
            WHERE u.phone = @Phone
            ORDER BY o.createdAt DESC";

        var orders = await connection.QueryAsync<OrderInfo>(sql, new { Phone = phone });
        return orders.ToList();
    }

    // ==================== CHAT HISTORY ====================

    [KernelFunction("save_chat")]
    [Description("Lưu lịch sử chat vào database")]
    public async Task SaveChatAsync(
        [Description("ID người dùng")] string userId,
        [Description("Câu hỏi của khách")] string userMessage,
        [Description("Câu trả lời của AI")] string aiResponse,
        [Description("Ý định câu hỏi")] string? intent = null,
        [Description("ID sản phẩm liên quan")] string? productId = null,
        [Description("ID đơn hàng liên quan")] string? orderId = null,
        [Description("Thời gian phản hồi (ms)")] int? responseTimeMs = null)
    {
        using var connection = CreateConnection();
        var sessionId = Guid.NewGuid().ToString();
        var chatId = "CH" + DateTime.Now.ToString("yyyyMMddHHmmss") + new Random().Next(1000, 9999).ToString();

        var metadata = new
        {
            productId,
            orderId,
            timestamp = DateTime.Now
        };

        var sql = @"
        INSERT INTO ChatHistory 
        (chatId, userId, sessionId, userMessage, aiResponse, intent, responseTimeMs, metadata, createdAt)
        VALUES 
        (@ChatId, @UserId, @SessionId, @UserMessage, @AiResponse, @Intent, @ResponseTimeMs, @Metadata, @CreatedAt)";

        var result = await connection.ExecuteAsync(sql, new
        {
            ChatId = chatId,
            UserId = userId,
            SessionId = sessionId,
            UserMessage = userMessage,
            AiResponse = aiResponse,
            Intent = intent,
            ResponseTimeMs = responseTimeMs,
            Metadata = System.Text.Json.JsonSerializer.Serialize(metadata),
            CreatedAt = DateTime.Now
        });

        Console.WriteLine($"Đã lưu chat: {result} dòng ảnh hưởng, ChatId: {chatId}");
    }

    [KernelFunction("get_chat_history")]
    [Description("Lấy lịch sử chat của người dùng")]
    public async Task<IEnumerable<ChatRecord>> GetChatHistoryAsync(
        [Description("ID người dùng")] string userId,
        [Description("Số lượng tin nhắn")] int limit = 10)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT TOP (@Limit) 
                chatId, userMessage, aiResponse, intent, 
                CASE WHEN isResolved = 1 THEN 'Đã giải quyết' ELSE 'Chưa đánh giá' END as status,
                createdAt
            FROM ChatHistory 
            WHERE userId = @UserId 
            ORDER BY createdAt DESC";

        return await connection.QueryAsync<ChatRecord>(sql, new { UserId = userId, Limit = limit });
    }
}

// ==================== DTOs ====================

public class ProductInfo
{
    public string? ProductId { get; set; }
    public string? ProductName { get; set; }
    public decimal? Price { get; set; }
    public string? Unit { get; set; }
    public int? StockQuantity { get; set; }
    public string? CategoryName { get; set; }
    public string? SupplierName { get; set; }

    public string DisplayText => $"""
        🍎 **{ProductName}**
        💰 Giá: {Price:N0}đ/{Unit}
        📦 Còn lại: {StockQuantity} {Unit}
        🏷️ Danh mục: {CategoryName}
        🔗 [Xem chi tiết](https://fruitstore.com/products/{ProductId})
        """;
}

public class ProductDetail : ProductInfo
{
    public string? Description { get; set; }
    public string? SupplierPhone { get; set; }
}

public class OrderInfo
{
    public string? OrderId { get; set; }
    public string? UserId { get; set; }
    public decimal? TotalAmount { get; set; }
    public decimal? DiscountAmount { get; set; }
    public decimal? FinalAmount { get; set; }
    public string? Status { get; set; }
    public string? PaymentMethod { get; set; }
    public string? DeliveryAddress { get; set; }
    public DateTime? CreatedAt { get; set; }
    public string? Phone { get; set; }
    public string? FullName { get; set; }

    public string DisplayText => $"""
        📦 **Đơn hàng: {OrderId}**
        👤 Khách hàng: {FullName ?? "Không xác định"}
        📅 Ngày đặt: {CreatedAt:dd/MM/yyyy HH:mm}
        💰 Tổng tiền: {TotalAmount:N0}đ
        🎁 Giảm giá: {DiscountAmount:N0}đ
        💵 Thành tiền: **{FinalAmount:N0}đ**
        📍 Trạng thái: {GetStatusText()}
        🚚 Địa chỉ: {DeliveryAddress}
        🔗 [Theo dõi đơn hàng](https://fruitstore.com/orders/tracking?code={OrderId})
        """;

    private string GetStatusText() => Status switch
    {
        "pending" => "⏳ Chờ xác nhận",
        "processing" => "🔄 Đang xử lý",
        "shipping" => "🚚 Đang giao hàng",
        "completed" => "✅ Đã giao thành công",
        "cancelled" => "❌ Đã hủy",
        _ => Status ?? "Không xác định"
    };
}

public class ChatRecord
{
    public string? ChatId { get; set; }
    public string? UserMessage { get; set; }
    public string? AiResponse { get; set; }
    public string? Intent { get; set; }
    public string? Status { get; set; }
    public DateTime CreatedAt { get; set; }
}
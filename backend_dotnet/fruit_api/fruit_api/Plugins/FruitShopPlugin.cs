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

    // ==================== LỌC SẢN PHẨM THEO GIÁ (BỔ SUNG) ====================

    [KernelFunction("get_products_by_price_range")]
    [Description("Lấy danh sách sản phẩm trong khoảng giá")]
    public async Task<List<ProductInfo>> GetProductsByPriceRangeAsync(
        [Description("Giá tối thiểu (VND), có thể để null")] decimal? minPrice = null,
        [Description("Giá tối đa (VND), có thể để null")] decimal? maxPrice = null)
    {
        using var connection = CreateConnection();

        var conditions = new List<string> { "p.isActive = 1" };
        var parameters = new DynamicParameters();

        if (minPrice.HasValue)
        {
            conditions.Add("p.price >= @MinPrice");
            parameters.Add("MinPrice", minPrice.Value);
        }

        if (maxPrice.HasValue)
        {
            conditions.Add("p.price <= @MaxPrice");
            parameters.Add("MaxPrice", maxPrice.Value);
        }

        var sql = $@"
            SELECT p.productId, p.productName, p.price, p.unit, p.stockQuantity,
                   c.categoryName, s.supplierName
            FROM Products p
            LEFT JOIN Categories c ON p.categoryId = c.categoryId
            LEFT JOIN Suppliers s ON p.supplierId = s.supplierId
            WHERE {string.Join(" AND ", conditions)}
            ORDER BY p.price ASC";

        var products = await connection.QueryAsync<ProductInfo>(sql, parameters);
        return products.ToList();
    }

    [KernelFunction("get_cheapest_products")]
    [Description("Lấy danh sách sản phẩm có giá thấp nhất")]
    public async Task<List<ProductInfo>> GetCheapestProductsAsync(
        [Description("Số lượng sản phẩm muốn lấy (mặc định 5)")] int limit = 5)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT TOP (@Limit) p.productId, p.productName, p.price, p.unit, p.stockQuantity,
                   c.categoryName, s.supplierName
            FROM Products p
            LEFT JOIN Categories c ON p.categoryId = c.categoryId
            LEFT JOIN Suppliers s ON p.supplierId = s.supplierId
            WHERE p.isActive = 1
            ORDER BY p.price ASC";

        var products = await connection.QueryAsync<ProductInfo>(sql, new { Limit = limit });
        return products.ToList();
    }

    [KernelFunction("get_most_expensive_products")]
    [Description("Lấy danh sách sản phẩm có giá cao nhất")]
    public async Task<List<ProductInfo>> GetMostExpensiveProductsAsync(
        [Description("Số lượng sản phẩm muốn lấy (mặc định 5)")] int limit = 5)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT TOP (@Limit) p.productId, p.productName, p.price, p.unit, p.stockQuantity,
                   c.categoryName, s.supplierName
            FROM Products p
            LEFT JOIN Categories c ON p.categoryId = c.categoryId
            LEFT JOIN Suppliers s ON p.supplierId = s.supplierId
            WHERE p.isActive = 1
            ORDER BY p.price DESC";

        var products = await connection.QueryAsync<ProductInfo>(sql, new { Limit = limit });
        return products.ToList();
    }

    // ==================== LỌC THEO DANH MỤC ====================

    [KernelFunction("get_products_by_category")]
    [Description("Lấy danh sách sản phẩm theo danh mục")]
    public async Task<List<ProductInfo>> GetProductsByCategoryAsync(
        [Description("Tên danh mục (ví dụ: Táo, Cam, Thanh Long)")] string categoryName)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT p.productId, p.productName, p.price, p.unit, p.stockQuantity,
                   c.categoryName, s.supplierName
            FROM Products p
            LEFT JOIN Categories c ON p.categoryId = c.categoryId
            LEFT JOIN Suppliers s ON p.supplierId = s.supplierId
            WHERE p.isActive = 1 AND c.categoryName LIKE @CategoryName";

        var products = await connection.QueryAsync<ProductInfo>(sql, new { CategoryName = $"%{categoryName}%" });
        return products.ToList();
    }

    [KernelFunction("get_all_categories")]
    [Description("Lấy danh sách tất cả danh mục sản phẩm")]
    public async Task<List<string>> GetAllCategoriesAsync()
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT DISTINCT c.categoryName
            FROM Categories c
            WHERE c.isActive = 1
            ORDER BY c.categoryName";

        var categories = await connection.QueryAsync<string>(sql);
        return categories.ToList();
    }

    // ==================== LỌC THEO NHÀ CUNG CẤP ====================

    [KernelFunction("get_products_by_supplier")]
    [Description("Lấy danh sách sản phẩm theo nhà cung cấp")]
    public async Task<List<ProductInfo>> GetProductsBySupplierAsync(
        [Description("Tên nhà cung cấp")] string supplierName)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT p.productId, p.productName, p.price, p.unit, p.stockQuantity,
                   c.categoryName, s.supplierName
            FROM Products p
            LEFT JOIN Categories c ON p.categoryId = c.categoryId
            LEFT JOIN Suppliers s ON p.supplierId = s.supplierId
            WHERE p.isActive = 1 AND s.supplierName LIKE @SupplierName";

        var products = await connection.QueryAsync<ProductInfo>(sql, new { SupplierName = $"%{supplierName}%" });
        return products.ToList();
    }

    // ==================== SẮP XẾP SẢN PHẨM ====================

    [KernelFunction("sort_products_by_price")]
    [Description("Lấy danh sách sản phẩm sắp xếp theo giá (tăng hoặc giảm)")]
    public async Task<List<ProductInfo>> SortProductsByPriceAsync(
        [Description("Cách sắp xếp: 'asc' cho tăng dần, 'desc' cho giảm dần")] string order = "asc",
        [Description("Số lượng sản phẩm muốn lấy (mặc định 10)")] int limit = 10)
    {
        using var connection = CreateConnection();
        var sortOrder = order.ToLower() == "desc" ? "DESC" : "ASC";

        var sql = $@"
            SELECT TOP (@Limit) p.productId, p.productName, p.price, p.unit, p.stockQuantity,
                   c.categoryName, s.supplierName
            FROM Products p
            LEFT JOIN Categories c ON p.categoryId = c.categoryId
            LEFT JOIN Suppliers s ON p.supplierId = s.supplierId
            WHERE p.isActive = 1
            ORDER BY p.price {sortOrder}";

        var products = await connection.QueryAsync<ProductInfo>(sql, new { Limit = limit });
        return products.ToList();
    }

    // ==================== THỐNG KÊ ====================

    [KernelFunction("get_price_statistics")]
    [Description("Lấy thống kê giá sản phẩm (giá thấp nhất, cao nhất, trung bình)")]
    public async Task<PriceStatistics> GetPriceStatisticsAsync()
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT 
                MIN(price) as MinPrice,
                MAX(price) as MaxPrice,
                AVG(price) as AvgPrice,
                COUNT(*) as TotalProducts
            FROM Products
            WHERE isActive = 1";

        var stats = await connection.QueryFirstOrDefaultAsync<PriceStatistics>(sql);
        return stats ?? new PriceStatistics();
    }

    // ==================== KHUYẾN MÃI (ĐÃ SỬA) ====================

    [KernelFunction("get_active_vouchers")]
    [Description("Lấy danh sách voucher đang hoạt động và còn lượt sử dụng")]
    public async Task<List<VoucherInfo>> GetActiveVouchersAsync()
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT 
                voucherId,
                voucherCode as voucherName,
                discountType,
                discountValue,
                minOrderValue,
                maxDiscountValue as maxDiscount,
                startDate,
                endDate,
                quantity,
                usedQuantity,
                status
            FROM Vouchers
            WHERE status = 'active' 
                AND quantity > usedQuantity
                AND (startDate IS NULL OR startDate <= GETDATE())
                AND (endDate IS NULL OR endDate >= GETDATE())
            ORDER BY discountValue DESC, createdAt DESC";

        var vouchers = await connection.QueryAsync<VoucherInfo>(sql);

        Console.WriteLine($"[DEBUG] GetActiveVouchersAsync: found {vouchers.Count()} active vouchers");

        return vouchers.ToList();
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
                   orderStatus as status, paymentMethod, deliveryAddress, createdAt,
                   ReceiverName
            FROM Orders 
            WHERE orderId = @OrderCode";

        var result = await connection.QueryFirstOrDefaultAsync<OrderInfo>(sql, new { OrderCode = orderCode });

        Console.WriteLine($"[DEBUG] CheckOrderAsync: orderCode={orderCode}, found={result != null}, status={result?.Status}, receiver={result?.ReceiverName}");

        return result;
    }

    [KernelFunction("get_orders_by_phone")]
    [Description("Lấy danh sách đơn hàng theo số điện thoại")]
    public async Task<List<OrderInfo>> GetOrdersByPhoneAsync(
        [Description("Số điện thoại khách hàng")] string phone)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT o.orderId, o.userId, o.totalAmount, o.discountAmount, o.finalAmount, 
                   o.orderStatus as status, o.paymentMethod, o.deliveryAddress, o.createdAt,
                   u.phone, o.ReceiverName
            FROM Orders o
            JOIN Users u ON o.userId = u.userId
            WHERE u.phone = @Phone
            ORDER BY o.createdAt DESC";

        var orders = await connection.QueryAsync<OrderInfo>(sql, new { Phone = phone });

        Console.WriteLine($"[DEBUG] GetOrdersByPhoneAsync: phone={phone}, found={orders.Count()}");

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
    public string? ReceiverName { get; set; }

    public string DisplayText => $"""
        📦 **Đơn hàng: {OrderId}**
        👤 Khách hàng: {ReceiverName ?? "Không xác định"}
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

// ==================== DTOs BỔ SUNG ====================

public class PriceStatistics
{
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public decimal? AvgPrice { get; set; }
    public int TotalProducts { get; set; }

    public string DisplayText => $"""
        📊 **Thống kê giá sản phẩm**
        💚 Giá thấp nhất: {MinPrice:N0}đ
        💛 Giá cao nhất: {MaxPrice:N0}đ
        💙 Giá trung bình: {AvgPrice:N0}đ
        🍎 Tổng số sản phẩm: {TotalProducts}
        """;
}

public class VoucherInfo
{
    public string? VoucherId { get; set; }
    public string? VoucherName { get; set; }
    public string? DiscountType { get; set; }
    public decimal? DiscountValue { get; set; }
    public decimal? MinOrderValue { get; set; }
    public decimal? MaxDiscount { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public int? Quantity { get; set; }
    public int? UsedQuantity { get; set; }
    public string? Status { get; set; }

    public int RemainingQuantity => (Quantity ?? 0) - (UsedQuantity ?? 0);

    public string DisplayText
    {
        get
        {
            // Xử lý hiển thị giảm giá
            string discountText;
            if (DiscountType?.ToLower() == "percent")
            {
                discountText = $"{DiscountValue}%";
            }
            else if (DiscountType?.ToLower() == "fixed")
            {
                discountText = $"{DiscountValue:N0}đ";
            }
            else
            {
                discountText = $"{DiscountValue:N0}đ";
            }

            // Kiểm tra còn voucher không
            string stockText;
            if (RemainingQuantity <= 0)
            {
                stockText = "⚠️ Hết lượt sử dụng";
            }
            else if (RemainingQuantity < 10)
            {
                stockText = $"🎟️ Chỉ còn {RemainingQuantity} voucher! Số lượng có hạn!";
            }
            else
            {
                stockText = $"🎟️ Còn lại: {RemainingQuantity} voucher";
            }

            // Điều kiện đơn tối thiểu
            string minOrderText = MinOrderValue.HasValue && MinOrderValue > 0
                ? $"📋 Đơn tối thiểu: {MinOrderValue:N0}đ"
                : "📋 Không yêu cầu đơn tối thiểu";

            // Giảm tối đa
            string maxDiscountText = MaxDiscount.HasValue && MaxDiscount > 0
                ? $"🔝 Giảm tối đa: {MaxDiscount:N0}đ"
                : "🔝 Không giới hạn giảm tối đa";

            // Ngày hết hạn
            string expiryText = "";
            if (EndDate.HasValue)
            {
                var daysLeft = (EndDate.Value - DateTime.Now).Days;
                if (daysLeft <= 3 && daysLeft > 0)
                {
                    expiryText = $"⚠️ Sắp hết hạn! Còn {daysLeft} ngày";
                }
                else if (daysLeft <= 0)
                {
                    expiryText = "❌ Đã hết hạn";
                }
                else
                {
                    expiryText = $"📅 Hạn: {EndDate:dd/MM/yyyy}";
                }
            }

            return $"""
                🎫 **{VoucherName}**
                💰 Giảm: {discountText}
                {minOrderText}
                {maxDiscountText}
                {stockText}
                {expiryText}
                """;
        }
    }
}
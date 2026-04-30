using fruit_api.Plugins;
using fruit_api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using System.Diagnostics;
using System.Security.Claims;
using System.Text.RegularExpressions;

namespace fruit_api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChatController : ControllerBase
{
    private readonly Kernel _kernel;
    private readonly IChatCompletionService _chatService;
    private readonly ILogger<ChatController> _logger;
    private readonly FruitShopPlugin _plugin;
    private readonly ChatHistoryService _historyService;

    public ChatController(
        Kernel kernel,
        IChatCompletionService chatService,
        ILogger<ChatController> logger,
        FruitShopPlugin plugin,
        ChatHistoryService historyService)
    {
        _kernel = kernel;
        _chatService = chatService;
        _logger = logger;
        _plugin = plugin;
        _historyService = historyService;
    }

    private string GetUserId()
    {
        return User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("nameid")?.Value
            ?? "anonymous";
    }

    // ================== REGEX ==================

    private string? ExtractOrderCode(string text)
    {
        var match = Regex.Match(text, @"\b(OD|DH)\d{6}\b", RegexOptions.IgnoreCase);
        if (match.Success)
        {
            var code = match.Value.ToUpper();
            Console.WriteLine($"[DEBUG] Found order code: {code}");
            return code;
        }

        Console.WriteLine($"[DEBUG] No order code found in: {text}");
        return null;
    }

    private string? ExtractPhone(string text)
    {
        var match = Regex.Match(text, @"\b0\d{9}\b");
        return match.Success ? match.Value : null;
    }

    private bool IsOrderQuestion(string text)
    {
        text = text.ToLower();
        return text.Contains("đơn") || text.Contains("order") || text.Contains("giao");
    }

    // ================== LẤY LỊCH SỬ CHAT ==================

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory([FromQuery] int limit = 20)
    {
        try
        {
            var userId = GetUserId();

            // Gọi Plugin để lấy lịch sử từ database
            var history = await _plugin.GetChatHistoryAsync(userId, limit);

            Console.WriteLine($"[DEBUG] GetHistory: userId={userId}, count={history.Count()}");

            return Ok(history);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi lấy lịch sử chat");
            return StatusCode(500, new { error = "Không thể lấy lịch sử", detail = ex.Message });
        }
    }

    // ================== MAIN ==================

    [HttpPost("ask")]
    public async Task<IActionResult> Ask([FromBody] ChatRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Question))
            return BadRequest("Câu hỏi trống");

        var userId = GetUserId();
        var question = request.Question.Trim();
        var lower = question.ToLower();

        Console.WriteLine($"[DEBUG] ========== NEW REQUEST ==========");
        Console.WriteLine($"[DEBUG] UserId: {userId}");
        Console.WriteLine($"[DEBUG] Question: {question}");
        Console.WriteLine($"[DEBUG] Lower: {lower}");

        // ================== 1. XỬ LÝ ĐƠN HÀNG (KHÔNG QUA AI) ==================

        if (IsOrderQuestion(lower))
        {
            Console.WriteLine($"[DEBUG] IsOrderQuestion = TRUE");

            var orderCode = ExtractOrderCode(question);
            var phone = ExtractPhone(question);

            Console.WriteLine($"[DEBUG] orderCode = '{orderCode}'");
            Console.WriteLine($"[DEBUG] phone = '{phone}'");

            if (!string.IsNullOrEmpty(orderCode))
            {
                Console.WriteLine($"[DEBUG] Checking order with code: {orderCode}");

                var order = await _plugin.CheckOrderAsync(orderCode);

                Console.WriteLine($"[DEBUG] Order found: {order != null}");
                Console.WriteLine($"[DEBUG] Order details: {order?.OrderId}, Status: {order?.Status}");

                if (order != null)
                    return Ok(new ChatResponse { Answer = order.DisplayText, Intent = "order" });

                return Ok(new ChatResponse { Answer = "❌ Không tìm thấy đơn hàng." });
            }

            if (!string.IsNullOrEmpty(phone))
            {
                Console.WriteLine($"[DEBUG] Checking orders with phone: {phone}");

                var orders = await _plugin.GetOrdersByPhoneAsync(phone);

                Console.WriteLine($"[DEBUG] Orders found: {orders.Count()}");

                if (orders.Any())
                {
                    var text = string.Join("\n\n", orders.Take(3).Select(o => o.DisplayText));
                    return Ok(new ChatResponse { Answer = text, Intent = "order" });
                }

                return Ok(new ChatResponse { Answer = "❌ Không có đơn nào với số này." });
            }

            Console.WriteLine($"[DEBUG] No order code or phone found - asking for more info");
            return Ok(new ChatResponse
            {
                Answer = "📦 Bạn cho mình mã đơn (VD: DH001) hoặc số điện thoại để mình kiểm tra nhé!"
            });
        }

        Console.WriteLine($"[DEBUG] IsOrderQuestion = FALSE - going to AI");

        // ================== 2. AI CHAT ==================

        var history = _historyService.GetOrCreateHistory(userId);

        if (history.Count <= 1 && request.History != null)
        {
            foreach (var msg in request.History)
            {
                if (msg.IsUser) history.AddUserMessage(msg.Content);
                else history.AddAssistantMessage(msg.Content);
            }
        }

        history.AddUserMessage(question);

        var settings = new OpenAIPromptExecutionSettings
        {
            Temperature = 0.4,
            MaxTokens = 1000,
            FunctionChoiceBehavior = FunctionChoiceBehavior.Auto()
        };

        var sw = Stopwatch.StartNew();
        var result = await _chatService.GetChatMessageContentAsync(history, settings, _kernel);
        sw.Stop();

        var answer = result.Content ?? "Xin lỗi, mình chưa hiểu rõ câu hỏi.";

        history.AddAssistantMessage(answer);
        _historyService.UpdateHistory(userId, history);

        // Lưu vào database
        try
        {
            await _plugin.SaveChatAsync(
                userId,
                question,
                answer,
                "general",
                null,
                null,
                (int)sw.ElapsedMilliseconds
            );
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Không thể lưu chat vào database");
        }

        Console.WriteLine($"[DEBUG] AI Response time: {sw.ElapsedMilliseconds}ms");
        Console.WriteLine($"[DEBUG] AI Answer: {answer?.Substring(0, Math.Min(100, answer?.Length ?? 0))}...");

        return Ok(new ChatResponse
        {
            Answer = answer,
            Intent = "general",
            ResponseTimeMs = sw.ElapsedMilliseconds
        });
    }

    [HttpGet("ping")]
    public IActionResult Ping() => Ok(new { status = "GreenFruit AI Online", time = DateTime.Now });

    // ================== DTO ==================

    public class ChatRequest
    {
        public string Question { get; set; } = "";
        public List<ChatHistoryItemDto>? History { get; set; }
    }

    public class ChatHistoryItemDto
    {
        public bool IsUser { get; set; }
        public string Content { get; set; } = "";
    }

    public class ChatResponse
    {
        public string Answer { get; set; } = "";
        public string Intent { get; set; } = "";
        public long ResponseTimeMs { get; set; }
    }
}
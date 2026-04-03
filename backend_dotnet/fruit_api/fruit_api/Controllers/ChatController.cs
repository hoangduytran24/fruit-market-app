using fruit_api.Plugins;
using fruit_api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using System.Diagnostics;
using System.Security.Claims;

namespace fruit_api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChatController : ControllerBase
{
    private readonly Kernel _kernel;
    private readonly IChatCompletionService _chatService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ChatController> _logger;
    private readonly FruitShopPlugin _fruitShopPlugin;
    private readonly ChatHistoryService _historyService;

    public ChatController(
        Kernel kernel,
        IChatCompletionService chatService,
        IConfiguration configuration,
        ILogger<ChatController> logger,
        FruitShopPlugin fruitShopPlugin,
        ChatHistoryService historyService)
    {
        _kernel = kernel;
        _chatService = chatService;
        _configuration = configuration;
        _logger = logger;
        _fruitShopPlugin = fruitShopPlugin;
        _historyService = historyService;
    }

    // Helper lấy userId từ token
    private string GetUserId()
    {
        // Lấy userId từ claim "nameid" (ClaimTypes.NameIdentifier)
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                    ?? User.FindFirst("nameid")?.Value
                    ?? "anonymous";
        return userId;
    }

    [HttpPost("ask")]
    public async Task<IActionResult> Ask([FromBody] ChatRequest request)
    {
        if (string.IsNullOrEmpty(request.Question))
            return BadRequest(new { error = "Câu hỏi không được trống." });

        try
        {
            var userId = GetUserId();

            _logger.LogInformation("User {UserId} asked: {Question}", userId, request.Question);

            // 1. Lấy history từ RAM (Service)
            var chatHistory = _historyService.GetOrCreateHistory(userId);

            // 2. Nếu RAM trống nhưng Flutter gửi history lên (do mới mở app), nạp vào RAM
            if (chatHistory.Count <= 1 && request.History != null && request.History.Any())
            {
                foreach (var msg in request.History)
                {
                    if (msg.IsUser) chatHistory.AddUserMessage(msg.Content);
                    else chatHistory.AddAssistantMessage(msg.Content);
                }
            }

            chatHistory.AddUserMessage(request.Question);

            var executionSettings = new OpenAIPromptExecutionSettings
            {
                Temperature = 0.3,
                MaxTokens = 1000,
                FunctionChoiceBehavior = FunctionChoiceBehavior.Auto()
            };

            var stopwatch = Stopwatch.StartNew();
            var result = await _chatService.GetChatMessageContentAsync(chatHistory, executionSettings, _kernel);
            stopwatch.Stop();

            var aiResponse = result.Content ?? "Xin lỗi, tôi gặp chút trục trặc.";
            chatHistory.AddAssistantMessage(aiResponse);

            // Cập nhật lại RAM
            _historyService.UpdateHistory(userId, chatHistory);

            var intent = DetectIntent(request.Question);

            // 3. LƯU VÀO SQL SERVER
            try
            {
                await _fruitShopPlugin.SaveChatAsync(
                    userId,           // userId
                    request.Question, // userMessage
                    aiResponse,       // aiResponse
                    intent,           // intent
                    null,             // productId
                    null,             // orderId
                    (int)stopwatch.ElapsedMilliseconds);  // responseTimeMs

                _logger.LogInformation("Saved chat to database for user {UserId}", userId);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Lỗi lưu SQL cho user {UserId}", userId);
            }

            return Ok(new ChatResponse
            {
                Answer = aiResponse,
                Intent = intent,
                ResponseTimeMs = stopwatch.ElapsedMilliseconds
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi Chat AI");
            return StatusCode(500, new { error = "Lỗi hệ thống AI", detail = ex.Message });
        }
    }

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory([FromQuery] int limit = 20)
    {
        try
        {
            var userId = GetUserId();

            // Gọi Plugin để Query từ bảng ChatHistory
            var history = await _fruitShopPlugin.GetChatHistoryAsync(userId, limit);
            return Ok(history);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi lấy lịch sử chat");
            return StatusCode(500, new { error = "Không thể lấy lịch sử", detail = ex.Message });
        }
    }

    [HttpPost("reset")]
    public IActionResult Reset()
    {
        var userId = GetUserId();
        _historyService.ClearHistory(userId);
        return Ok(new { message = "Đã reset phiên chat tạm thời", userId = userId });
    }

    [HttpGet("ping")]
    public IActionResult Ping() => Ok(new { status = "GreenFruit AI Online", time = DateTime.Now });

    private string DetectIntent(string question)
    {
        question = question.ToLower();
        if (question.Contains("giảm giá") || question.Contains("khuyến mãi")) return "promotion";
        if (question.Contains("đơn hàng") || question.Contains("kiểm tra đơn")) return "order";
        if (question.Contains("giá") || question.Contains("mua") || question.Contains("táo") || question.Contains("xoài")) return "product";
        return "general";
    }
}

// DTOs
public class ChatRequest
{
    public string Question { get; set; } = string.Empty;
    public List<ChatHistoryItemDto>? History { get; set; }
}

public class ChatHistoryItemDto
{
    public bool IsUser { get; set; }
    public string Content { get; set; } = string.Empty;
}

public class ChatResponse
{
    public string Answer { get; set; } = string.Empty;
    public string Intent { get; set; } = string.Empty;
    public long ResponseTimeMs { get; set; }
}
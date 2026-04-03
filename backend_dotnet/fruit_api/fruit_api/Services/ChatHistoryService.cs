using System.Collections.Concurrent;
using Microsoft.SemanticKernel.ChatCompletion;

namespace fruit_api.Services;

public class ChatHistoryService
{
    private readonly ConcurrentDictionary<string, ChatHistory> _histories = new();
    private readonly IConfiguration _configuration;

    public ChatHistoryService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    // Lấy history hiện tại hoặc tạo mới
    public ChatHistory GetOrCreateHistory(string userId)
    {
        if (_histories.TryGetValue(userId, out var existingHistory))
        {
            return existingHistory;
        }

        var history = new ChatHistory();
        var systemPrompt = _configuration["SemanticKernel:SystemPrompt"]
            ?? "Bạn là trợ lý ảo của GreenFruit Market, chuyên tư vấn về trái cây tươi ngon.";
        history.AddSystemMessage(systemPrompt);

        _histories.TryAdd(userId, history);
        return history;
    }

    // Cho phép nạp history từ database vào RAM khi user mới vào app
    public void LoadHistoryFromDb(string userId, List<(string message, bool isUser)> dbHistory)
    {
        var history = new ChatHistory();
        var systemPrompt = _configuration["SemanticKernel:SystemPrompt"]
            ?? "Bạn là trợ lý ảo của GreenFruit Market, chuyên tư vấn về trái cây tươi ngon.";
        history.AddSystemMessage(systemPrompt);

        foreach (var item in dbHistory)
        {
            if (item.isUser) history.AddUserMessage(item.message);
            else history.AddAssistantMessage(item.message);
        }

        _histories[userId] = history;
    }

    public void UpdateHistory(string userId, ChatHistory history)
    {
        _histories[userId] = history;
    }

    public void ClearHistory(string userId)
    {
        _histories.TryRemove(userId, out _);
    }
}
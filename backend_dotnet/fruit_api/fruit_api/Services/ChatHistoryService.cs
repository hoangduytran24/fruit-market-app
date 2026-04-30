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

    // ==================== CORE ====================

    private string GetSystemPrompt()
    {
        return _configuration["SemanticKernel:SystemPrompt"]
            ?? "Bạn là trợ lý ảo của GreenFruit Market, chuyên tư vấn về trái cây tươi ngon.";
    }

    private ChatHistory CreateNewHistory()
    {
        var systemPrompt = GetSystemPrompt();

        // ⚠️ QUAN TRỌNG: inject systemPrompt ngay từ constructor
        return new ChatHistory(systemPrompt);
    }

    // ==================== PUBLIC METHODS ====================

    // Lấy history hiện tại hoặc tạo mới
    public ChatHistory GetOrCreateHistory(string userId)
    {
        return _histories.GetOrAdd(userId, _ => CreateNewHistory());
    }

    // Load history từ DB vào RAM
    public void LoadHistoryFromDb(string userId, List<(string message, bool isUser)> dbHistory)
    {
        var history = CreateNewHistory();

        if (dbHistory != null && dbHistory.Count > 0)
        {
            foreach (var item in dbHistory)
            {
                if (item.isUser)
                    history.AddUserMessage(item.message);
                else
                    history.AddAssistantMessage(item.message);
            }
        }

        _histories[userId] = history;
    }

    // Update lại history sau mỗi lần chat
    public void UpdateHistory(string userId, ChatHistory history)
    {
        _histories[userId] = history;
    }

    // Xóa history (reset phiên chat)
    public void ClearHistory(string userId)
    {
        _histories.TryRemove(userId, out _);
    }
}
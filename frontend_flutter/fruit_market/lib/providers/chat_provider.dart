import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isFirstLoad = true;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  // Tải lịch sử từ SQL (chỉ tải 1 lần)
  Future<void> fetchHistory(String? token) async {
    if (!_isFirstLoad) return;
    
    _isLoading = true;
    notifyListeners();

    final history = await _chatService.getChatHistory(token);
    _messages = history;
    _isFirstLoad = false;
    
    _isLoading = false;
    notifyListeners();
  }

  // Thêm tin nhắn mới vào danh sách hiển thị
  void addMessage(String text, bool isUser) {
    _messages.add(ChatMessage(
      text: text,
      isUser: isUser,
      time: DateTime.now(),
    ));
    notifyListeners();
  }

  // Xóa toàn bộ tin nhắn
  void clearMessages() {
    _messages.clear();
    _isFirstLoad = true;
    notifyListeners();
  }
  
  // Lấy 10 tin nhắn gần nhất để làm context cho AI
  List<ChatMessage> getRecentMessages({int limit = 10}) {
    if (_messages.length <= limit) {
      return List.from(_messages);
    }
    return List.from(_messages.sublist(_messages.length - limit));
  }
}
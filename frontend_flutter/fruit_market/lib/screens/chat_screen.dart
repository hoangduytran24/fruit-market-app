import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _apiService = ChatService();

  bool _isTyping = false;
  bool _isConnected = true;

  final List<SuggestionQuestion> _suggestions = [
    SuggestionQuestion(
      icon: Icons.local_offer,
      title: 'Hôm nay có gì đặc biệt?',
      question: 'Hôm nay có sản phẩm khuyến mãi gì không?',
    ),
    SuggestionQuestion(
      icon: Icons.favorite,
      title: 'Trái cây tươi ngon',
      question: 'Trái cây nào đang được yêu thích nhất?',
    ),
    SuggestionQuestion(
      icon: Icons.delivery_dining,
      title: 'Kiểm tra đơn hàng',
      question: 'Kiểm tra đơn hàng của tôi',
    ),
    SuggestionQuestion(
      icon: Icons.support_agent,
      title: 'Hỗ trợ nhanh',
      question: 'Tôi cần hỗ trợ gấp',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkConnection();
    
    // Tải lịch sử từ SQL khi vào trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      // Chỉ add tin chào mừng nếu chưa có tin nhắn nào
      if (chatProvider.messages.isEmpty) {
        chatProvider.addMessage(
          'Xin chào! Tôi là trợ lý ảo của GreenFruit Market 🌟\n\nTôi có thể giúp gì cho bạn hôm nay?', 
          false
        );
        chatProvider.fetchHistory(authProvider.token);
      }
      _scrollToBottom();
    });
  }

  Future<void> _checkConnection() async {
    try {
      final isConnected = await _apiService.ping();
      if (mounted) {
        setState(() => _isConnected = isConnected);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnected = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final String? token = authProvider.token;

    // Thêm tin nhắn của User vào Provider
    chatProvider.addMessage(text, true);
    _messageController.clear();
    
    setState(() {
      _isTyping = true;
    });
    
    _scrollToBottom();

    try {
      // Lấy 10 tin nhắn gần nhất để làm context
      final recentMessages = chatProvider.getRecentMessages(limit: 10);
      
      // Gửi lên Backend
      final response = await _apiService.askAi(text, token, recentMessages);
      
      if (mounted) {
        setState(() => _isTyping = false);
        if (response != null && response.isNotEmpty) {
          chatProvider.addMessage(response, false);
        } else {
          chatProvider.addMessage('Xin lỗi, tôi không thể trả lời lúc này. Vui lòng thử lại sau! 🙏', false);
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        chatProvider.addMessage('Lỗi kết nối server: $e', false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(chatProvider),
      body: Column(
        children: [
          if (!_isConnected)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.red.shade700, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Mất kết nối server',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          if (chatProvider.isLoading)
            const LinearProgressIndicator(),
          Expanded(child: _buildMessageList(chatProvider)),
          if (chatProvider.messages.length <= 1) _buildSuggestions(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatProvider chatProvider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      title: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.android, color: Colors.white, size: 24)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FruitBot AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isConnected ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: _isConnected ? const Color(0xFF4CAF50) : Colors.red),
                    const SizedBox(width: 4),
                    Text(_isConnected ? 'Đang hoạt động' : 'Mất kết nối', style: TextStyle(fontSize: 10, color: _isConnected ? const Color(0xFF4CAF50) : Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF2C3E50)),
          onPressed: () {
            chatProvider.clearMessages();
            chatProvider.addMessage('Xin chào! Tôi là trợ lý ảo của GreenFruit Market 🌟\n\nTôi có thể giúp gì cho bạn hôm nay?', false);
            _checkConnection();
            _scrollToBottom();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageList(ChatProvider chatProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: chatProvider.messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatProvider.messages.length && _isTyping) {
          return const _TypingIndicator();
        }
        return _buildMessageBubble(chatProvider.messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)]) : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4), bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: isUser
                  ? Text(message.text, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white))
                  : MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF2C3E50)),
                        a: const TextStyle(color: Color(0xFF4CAF50), decoration: TextDecoration.underline),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(_formatTime(message.time), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text('✨ Câu hỏi gợi ý', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return Container(
                  width: 140, margin: const EdgeInsets.only(right: 12),
                  child: Material(
                    borderRadius: BorderRadius.circular(16), color: Colors.white,
                    child: InkWell(
                      onTap: () => _sendMessage(suggestion.question),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(suggestion.icon, color: const Color(0xFF4CAF50), size: 28),
                            const SizedBox(height: 8),
                            Text(suggestion.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50))),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey[300]!, width: 1)),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(hintText: 'Nhập tin nhắn...', hintStyle: TextStyle(color: Colors.grey, fontSize: 14), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(_messageController.text),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)]), borderRadius: BorderRadius.circular(30)),
            child: IconButton(
              onPressed: () => _sendMessage(_messageController.text),
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.day == time.day && now.month == time.month && now.year == time.year) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class SuggestionQuestion {
  final IconData icon;
  final String title;
  final String question;
  
  SuggestionQuestion({
    required this.icon,
    required this.title,
    required this.question,
  });
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}
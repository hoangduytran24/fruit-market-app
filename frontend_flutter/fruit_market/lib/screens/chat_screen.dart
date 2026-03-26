import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Danh sách câu hỏi gợi ý
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
    // Thêm tin nhắn chào mừng
    _messages.add(ChatMessage(
      text: 'Xin chào! Tôi là trợ lý ảo của FruitStore 🌟\n\nTôi có thể giúp gì cho bạn hôm nay?',
      isUser: false,
      time: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();
    _messageController.clear();

    // Giả lập phản hồi từ AI
    Future.delayed(const Duration(milliseconds: 1000), () {
      _simulateAIResponse(text);
    });
  }

  void _simulateAIResponse(String userMessage) {
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: _getAIResponse(userMessage),
        isUser: false,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  String _getAIResponse(String message) {
    // Đây là logic giả lập, sau này bạn sẽ kết nối với API AI thực tế
    if (message.contains('đặc biệt') || message.contains('khuyến mãi')) {
      return '🍎 Hôm nay chúng tôi có chương trình "Mua 1 tặng 1" cho táo New Zealand!\n\n🥭 Cam sành cũng đang giảm 20% cho đơn từ 2kg.\n\nBạn muốn tôi tư vấn thêm về sản phẩm nào không?';
    } else if (message.contains('yêu thích') || message.contains('ngon')) {
      return '🔥 Top 3 trái cây bán chạy nhất hôm nay:\n\n1. 🍓 Dâu tây Đà Lạt - 85.000đ/hộp\n2. 🥝 Kiwi xanh New Zealand - 120.000đ/túi\n3. 🥭 Xoài cát Hòa Lộc - 95.000đ/kg\n\nBạn có muốn đặt hàng ngay không?';
    } else if (message.contains('đơn hàng')) {
      return '📦 Để kiểm tra đơn hàng, bạn vui lòng cung cấp:\n\n• Số điện thoại đặt hàng\n• Hoặc mã đơn hàng\n\nTôi sẽ tra cứu giúp bạn ngay! 🔍';
    } else if (message.contains('hỗ trợ')) {
      return '📞 Tôi kết nối bạn với nhân viên hỗ trợ ngay!\n\nThời gian phản hồi: ~2 phút\nHoặc bạn có thể gọi hotline: 1900.xxxx\n\nBạn cần hỗ trợ vấn đề gì ạ?';
    }
    return 'Cảm ơn bạn đã quan tâm! 🌟\n\nTôi có thể giúp bạn:\n• Tư vấn sản phẩm theo mùa\n• Kiểm tra đơn hàng\n• Cập nhật khuyến mãi\n• Hỗ trợ giao hàng\n\nBạn muốn tôi hỗ trợ gì ạ?';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          if (_messages.length == 1) _buildSuggestions(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      // ĐÃ XÓA leading (mũi tên quay lại)
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.android, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FruitBot AI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFF4CAF50)),
                    SizedBox(width: 4),
                    Text(
                      'Đang hoạt động',
                      style: TextStyle(fontSize: 10, color: Color(0xFF4CAF50)),
                    ),
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
            setState(() {
              _messages.clear();
              _messages.add(ChatMessage(
                text: 'Xin chào! Tôi là trợ lý ảo của FruitStore 🌟\n\nTôi có thể giúp gì cho bạn hôm nay?',
                isUser: false,
                time: DateTime.now(),
              ));
            });
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return const _TypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isUser ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _formatTime(message.time),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
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
            child: Text(
              '✨ Câu hỏi gợi ý',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: Material(
                    elevation: 0,
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    child: InkWell(
                      onTap: () => _sendMessage(suggestion.question),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              suggestion.icon,
                              color: const Color(0xFF4CAF50),
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              suggestion.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(_messageController.text),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
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

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });

  // Chuyển đổi từ JSON của API (ChatRecord) sang ChatMessage
  factory ChatMessage.fromApi(Map<String, dynamic> json, bool isUserMessage) {
    return ChatMessage(
      text: isUserMessage ? json['userMessage'] : json['aiResponse'],
      isUser: isUserMessage,
      time: DateTime.parse(json['createdAt']),
    );
  }
}
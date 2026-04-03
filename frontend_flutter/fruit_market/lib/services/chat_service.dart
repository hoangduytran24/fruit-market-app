import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/chat_message.dart';

class ChatService {
  // Thay IP này bằng IP máy tính của bạn nếu chạy máy ảo Android
  static const String baseUrl = 'https://10.0.2.2:7262';

  http.Client _createClient() {
    final HttpClient client = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    return IOClient(client);
  }

  // Lấy lịch sử từ bảng ChatHistory trong SQL
  Future<List<ChatMessage>> getChatHistory(String? token) async {
    try {
      final client = _createClient();
      final response = await client.get(
        Uri.parse('$baseUrl/api/Chat/history?limit=20'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('Get history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        print('Response body: $responseBody');
        
        List<dynamic> data = jsonDecode(responseBody);
        List<ChatMessage> history = [];

        // Mỗi record trong data có userMessage và aiResponse
        for (var item in data) {
          // Thêm tin nhắn của user
          history.add(ChatMessage(
            text: item['userMessage'] ?? '',
            isUser: true,
            time: DateTime.parse(item['createdAt'] ?? DateTime.now().toIso8601String()),
          ));
          // Thêm phản hồi của AI
          history.add(ChatMessage(
            text: item['aiResponse'] ?? '',
            isUser: false,
            time: DateTime.parse(item['createdAt'] ?? DateTime.now().toIso8601String()),
          ));
        }
        return history;
      }
      return [];
    } catch (e) {
      print("Lỗi ChatService (History): $e");
      return [];
    }
  }

  // Gửi câu hỏi mới (kèm history để AI nhớ ngữ cảnh)
  Future<String?> askAi(String question, String? token, List<ChatMessage> recentMessages) async {
    try {
      final client = _createClient();
      
      // Chuyển đổi lịch sử sang định dạng backend cần
      final history = recentMessages.map((msg) => {
        'isUser': msg.isUser,
        'content': msg.text,
      }).toList();
      
      final requestBody = {
        'question': question,
        'history': history,
      };
      
      print('Sending request: $requestBody');
      
      final response = await client.post(
        Uri.parse('$baseUrl/api/Chat/ask'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Ask AI response status: ${response.statusCode}');
      print('Ask AI response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer'];
      } else if (response.statusCode == 401) {
        return "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.";
      } else {
        return "Xin lỗi, tôi không thể trả lời lúc này.";
      }
    } catch (e) {
      print("Lỗi ChatService (Ask): $e");
      return "Lỗi kết nối: $e";
    }
  }
  
  // Ping để kiểm tra kết nối
  Future<bool> ping() async {
    try {
      final client = _createClient();
      final response = await client.get(
        Uri.parse('$baseUrl/api/Chat/ping'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Ping error: $e");
      return false;
    }
  }
}
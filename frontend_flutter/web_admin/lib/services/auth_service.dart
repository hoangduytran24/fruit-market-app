import 'dart:convert';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  // Lưu thông báo lỗi chi tiết để Provider có thể lấy và hiển thị
  static String? lastErrorMessage;

  static Future<User?> login(String emailOrUsername, String password) async {
    try {
      lastErrorMessage = null; 
      
      final response = await ApiService.postPublic('Auth/login', body: {
        'username': emailOrUsername,
        'password': password,
      });

      // Kiểm tra nếu Server trả về rỗng (Lỗi thường gặp khi Backend crash)
      if (response.body.isEmpty) {
        lastErrorMessage = 'Không có phản hồi từ máy chủ.';
        return null;
      }

      final data = json.decode(response.body);

      // TH 1: Đăng nhập thành công
      if (response.statusCode == 200) {
        final token = data['token'];
        if (token != null) {
          await ApiService.saveToken(token);
          return User.fromJson(data);
        }
        lastErrorMessage = 'Dữ liệu xác thực không hợp lệ (Missing Token).';
        return null;
      } 
      
      // TH 2: Sai thông tin hoặc lỗi logic từ Backend (400, 401)
      else if (response.statusCode == 400 || response.statusCode == 401) {
        // Ưu tiên lấy field "message" từ Backend của bạn
        lastErrorMessage = data['message'] ?? 'Tên đăng nhập hoặc mật khẩu không chính xác.';
        return null;
      } 
      
      // TH 3: Các lỗi Server khác
      else {
        lastErrorMessage = 'Lỗi hệ thống: ${response.statusCode}';
        return null;
      }
    } catch (e) {
      // Bắt lỗi CORS, lỗi kết nối mạng, lỗi parse JSON
      print('AuthService Login Fatal Error: $e');
      lastErrorMessage = 'Lỗi kết nối: Vui lòng kiểm tra API hoặc cấu hình CORS.';
      return null;
    }
  }

  static Future<User?> getCurrentUser() async {
    try {
      final response = await ApiService.get('Auth/me');
      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('GetUser Error: $e');
      return null;
    }
  }

  static Future<void> logout() async => await ApiService.removeToken();
  static Future<bool> isLoggedIn() async => await ApiService.isLoggedIn();
}
import 'dart:convert';
import 'api_service.dart';

class AuthService {
  // Đăng nhập
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await ApiService.post(
        'Auth/login',
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Lưu token
        await ApiService.saveToken(data['token']);
        
        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối đến server',
      };
    }
  }

  // Đăng ký
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        'Auth/register',
        body: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Lưu token (nếu API trả về token sau đăng ký)
        if (data['token'] != null) {
          await ApiService.saveToken(data['token']);
        }
        
        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Đăng ký thất bại',
        };
      }
    } catch (e) {
      print('Register error: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối đến server',
      };
    }
  }

  // Đăng xuất
  static Future<void> logout() async {
    await ApiService.removeToken();
  }

  // Kiểm tra trạng thái đăng nhập
  static Future<bool> isLoggedIn() async {
    return await ApiService.isLoggedIn();
  }

  // Lấy thông tin user hiện tại (nếu cần gọi API riêng)
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await ApiService.get('Auth/me');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }
}
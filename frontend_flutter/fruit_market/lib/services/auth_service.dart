import 'dart:convert';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await ApiService.postPublic(
        'Auth/login',
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await ApiService.saveToken(data['token']);
        if (data['userId'] != null) {
          await ApiService.saveUserId(data['userId'].toString());
        }
        if (data['role'] != null) {
          await ApiService.saveUserRole(data['role']);
        }
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Đăng nhập thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến server'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await ApiService.postPublic(
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
        if (data['token'] != null) await ApiService.saveToken(data['token']);
        if (data['userId'] != null) {
          await ApiService.saveUserId(data['userId'].toString());
        }
        await ApiService.saveUserRole(data['role'] ?? 'user');
        return {'success': true, 'data': data};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Đăng ký thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến server'};
    }
  }

  static Future<void> logout() async {
    await ApiService.clearAllUserData();
  }

  static Future<bool> isLoggedIn() async {
    return await ApiService.isLoggedIn();
  }

  static Future<String?> getToken() async {
    return await ApiService.getToken();
  }

  static Future<String?> getUserId() async {
    return await ApiService.getUserId();
  }

  static Future<String?> getUserRole() async {
    return await ApiService.getUserRole();
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await ApiService.get('Auth/me');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['id'] != null) await ApiService.saveUserId(data['id'].toString());
        if (data['role'] != null) await ApiService.saveUserRole(data['role']);
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
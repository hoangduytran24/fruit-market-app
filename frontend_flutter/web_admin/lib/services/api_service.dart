import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL cho từng nền tảng
  static String get baseUrl {
    if (kIsWeb) {
      // Chạy trên web - dùng localhost (Đảm bảo backend bật CORS)
      return 'https://localhost:7262/api/';
    } else {
      // Chạy trên mobile Android emulator dùng 10.0.2.2 thay vì localhost
      return 'https://10.0.2.2:7262/api/';
    }
  }

  // Headers cơ bản cho các request công khai
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Headers có chứa JWT Token lấy từ bộ nhớ máy
  static Future<Map<String, String>> get authHeaders async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- PRIVATE METHODS (Cần Token) ---

  static Future<http.Response> get(String endpoint) async {
    return await _handleRequest(() async {
      final url = '$baseUrl$endpoint';
      print('🌐 GET: $url');
      final headersWithAuth = await authHeaders;
      return await http.get(Uri.parse(url), headers: headersWithAuth);
    });
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    return await _handleRequest(() async {
      final url = '$baseUrl$endpoint';
      print('🌐 POST: $url');
      final headersWithAuth = await authHeaders;
      return await http.post(
        Uri.parse(url),
        headers: headersWithAuth,
        body: body != null ? json.encode(body) : null,
      );
    });
  }

  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    return await _handleRequest(() async {
      final url = '$baseUrl$endpoint';
      print('🌐 PUT: $url');
      final headersWithAuth = await authHeaders;
      return await http.put(
        Uri.parse(url),
        headers: headersWithAuth,
        body: body != null ? json.encode(body) : null,
      );
    });
  }

  // THÊM: Patch request dùng cho cập nhật trạng thái user/order
  static Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) async {
    return await _handleRequest(() async {
      final url = '$baseUrl$endpoint';
      print('🌐 PATCH: $url');
      final headersWithAuth = await authHeaders;
      return await http.patch(
        Uri.parse(url),
        headers: headersWithAuth,
        body: body != null ? json.encode(body) : null,
      );
    });
  }

  static Future<http.Response> delete(String endpoint) async {
    return await _handleRequest(() async {
      final url = '$baseUrl$endpoint';
      print('🌐 DELETE: $url');
      final headersWithAuth = await authHeaders;
      return await http.delete(Uri.parse(url), headers: headersWithAuth);
    });
  }

  // --- PUBLIC METHODS (Không cần Token) ---

  static Future<http.Response> postPublic(String endpoint, {Map<String, dynamic>? body}) async {
    return await _handleRequest(() async {
      final url = '$baseUrl$endpoint';
      print('🌐 POST Public: $url');
      return await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
    });
  }

  static Future<http.Response> getPublic(String endpoint) async {
    return await _handleRequest(() async {
      final url = '$baseUrl$endpoint';
      print('🌐 GET Public: $url');
      return await http.get(Uri.parse(url), headers: headers);
    });
  }

  // --- TOKEN MANAGEMENT ---

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  // --- HELPER ---
  // Hàm bổ trợ để quản lý log và lỗi chung
  static Future<http.Response> _handleRequest(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      print('📥 Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ ApiService Error: $e');
      rethrow;
    }
  }
}
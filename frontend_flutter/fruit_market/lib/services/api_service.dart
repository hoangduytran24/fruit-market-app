import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://10.0.2.2:7262/api/';
  
  // Headers cơ bản không có token
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers có token - dùng cho các request cần xác thực
  static Future<Map<String, String>> get authHeaders async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET request
  static Future<http.Response> get(String endpoint) async {
    try {
      print('🌐 GET: $baseUrl$endpoint');
      final headersWithAuth = await authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headersWithAuth,
      );
      print('📥 Response: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ GET Error: $e');
      rethrow;
    }
  }

  // POST request
  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      print('🌐 POST: $baseUrl$endpoint');
      print('📦 Body: $body');
      final headersWithAuth = await authHeaders;
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headersWithAuth,
        body: body != null ? json.encode(body) : null,
      );
      print('📥 Response: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ POST Error: $e');
      rethrow;
    }
  }

  // PUT request
  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      print('🌐 PUT: $baseUrl$endpoint');
      final headersWithAuth = await authHeaders;
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headersWithAuth,
        body: body != null ? json.encode(body) : null,
      );
      print('📥 Response: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ PUT Error: $e');
      rethrow;
    }
  }

  // DELETE request
  static Future<http.Response> delete(String endpoint) async {
    try {
      print('🌐 DELETE: $baseUrl$endpoint');
      final headersWithAuth = await authHeaders;
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headersWithAuth,
      );
      print('📥 Response: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ DELETE Error: $e');
      rethrow;
    }
  }

  // POST request không cần token (login, register)
  static Future<http.Response> postPublic(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      print('🌐 POST Public: $baseUrl$endpoint');
      print('📦 Body: $body');
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      print('📥 Response: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ POST Public Error: $e');
      rethrow;
    }
  }

  // GET request không cần token
  static Future<http.Response> getPublic(String endpoint) async {
    try {
      print('🌐 GET Public: $baseUrl$endpoint');
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      print('📥 Response: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ GET Public Error: $e');
      rethrow;
    }
  }

  // Lưu token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Xóa token
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Kiểm tra đăng nhập
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  // Lấy token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Xử lý response
  static dynamic handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Lỗi: ${response.statusCode}');
  }
}
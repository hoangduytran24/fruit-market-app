import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://10.0.2.2:7262/api/';
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> get authHeaders async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    try {
      final headersWithAuth = await authHeaders;
      return await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headersWithAuth,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headersWithAuth = await authHeaders;
      return await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headersWithAuth,
        body: body != null ? json.encode(body) : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headersWithAuth = await authHeaders;
      return await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headersWithAuth,
        body: body != null ? json.encode(body) : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> delete(String endpoint) async {
    try {
      final headersWithAuth = await authHeaders;
      return await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headersWithAuth,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> postPublic(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> getPublic(String endpoint) async {
    try {
      return await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  static Future<void> removeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  static Future<void> removeUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<void> clearAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
  }

  static dynamic handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Lỗi: ${response.statusCode}');
  }
}
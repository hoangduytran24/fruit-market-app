import 'dart:convert';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  
  // Đăng nhập
  Future<User?> login(String email, String password) async {
    try {
      final response = await ApiService.postPublic('Auth/login', body: {
        'username': email,
        'password': password,
      });
      
      print('📥 Login response status: ${response.statusCode}');
      print('📥 Login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Parsed data: $data');
        
        // Backend trả về thẳng user + token
        final userId = data['userId'];
        final fullName = data['fullName'];
        final email = data['email'];
        final phone = data['phone'];
        final role = data['role'];
        final token = data['token'];
        
        if (token != null && userId != null) {
          // Lưu token
          await ApiService.saveToken(token);
          
          // Tạo user object
          final user = User(
            userId: userId,
            fullName: fullName ?? '',
            email: email ?? '',
            phone: phone,
            role: role ?? 'user',
            status: 'active',
            createdAt: DateTime.now(),
          );
          
          return user;
        }
      }
      return null;
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }
  
  // Lấy thông tin user hiện tại
  Future<User?> getCurrentUser() async {
    try {
      final response = await ApiService.get('Auth/me');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Get current user error: $e');
      return null;
    }
  }
  
  // Đăng xuất
  Future<void> logout() async {
    await ApiService.removeToken();
  }
  
  // Kiểm tra đã đăng nhập chưa
  Future<bool> isAuthenticated() async {
    return await ApiService.isLoggedIn();
  }
}
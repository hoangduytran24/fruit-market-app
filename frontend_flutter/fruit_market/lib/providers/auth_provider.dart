import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class User {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? token;

  User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'token': token,
    };
  }
}

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  String? get token => _currentUser?.token;

  // Constructor - kiểm tra trạng thái đăng nhập khi khởi tạo
  AuthProvider() {
    checkLoginStatus();
  }

  // Kiểm tra trạng thái đăng nhập từ token đã lưu
  Future<void> checkLoginStatus() async {
    _setLoading(true);
    
    final isLoggedIn = await AuthService.isLoggedIn();
    
    if (isLoggedIn) {
      // Nếu có token, thử lấy thông tin user
      final userData = await AuthService.getCurrentUser();
      if (userData != null) {
        _currentUser = User.fromJson(userData);
      }
    }
    
    _setLoading(false);
  }

  // Đăng nhập
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.login(username, password);
      
      if (result['success']) {
        _currentUser = User.fromJson(result['data']);
        _setLoading(false);
        return true;
      } else {
        _error = result['message'];
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Đã có lỗi xảy ra';
      _setLoading(false);
      return false;
    }
  }

  // Đăng ký
  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      
      if (result['success']) {
        // Nếu API trả về token sau đăng ký, tự động đăng nhập
        if (result['data'] != null && result['data']['token'] != null) {
          _currentUser = User.fromJson(result['data']);
        }
        _setLoading(false);
        return true;
      } else {
        _error = result['message'];
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Đã có lỗi xảy ra';
      _setLoading(false);
      return false;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
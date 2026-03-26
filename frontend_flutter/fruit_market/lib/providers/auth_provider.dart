import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/User.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _hasLoaded = false; // THÊM
  bool _isChecking = false; // THÊM

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  String? get token => _currentUser?.token;
  bool get hasLoaded => _hasLoaded; // THÊM
  bool get isChecking => _isChecking; // THÊM

  // Constructor - kiểm tra trạng thái đăng nhập khi khởi tạo
  AuthProvider() {
    checkLoginStatus();
  }

  // Kiểm tra trạng thái đăng nhập từ token đã lưu
  Future<void> checkLoginStatus() async {
    // Nếu đã load hoặc đang check thì không làm gì
    if (_hasLoaded || _isChecking) {
      print('✅ Auth đã được load trước đó hoặc đang check');
      return;
    }
    
    _isChecking = true;
    _setLoading(true);
    
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      
      if (isLoggedIn) {
        final userData = await AuthService.getCurrentUser();
        if (userData != null) {
          _currentUser = User.fromJson(userData);
        }
      }
      
      _hasLoaded = true; // THÊM
    } catch (e) {
      print('❌ Error checking login status: $e');
    } finally {
      _isChecking = false;
      _setLoading(false);
    }
  }

  // Đăng nhập
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.login(username, password);
      
      if (result['success']) {
        _currentUser = User.fromJson(result['data']);
        _hasLoaded = true; // THÊM
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
        if (result['data'] != null && result['data']['token'] != null) {
          _currentUser = User.fromJson(result['data']);
        }
        _hasLoaded = true; // THÊM
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
    _hasLoaded = false; // THÊM: reset khi logout
    notifyListeners();
  }

  // Đảm bảo auth đã được load
  Future<void> ensureAuthLoaded() async {
    if (_hasLoaded) {
      print('✅ Auth đã được load trước đó');
      return;
    }
    
    if (_isChecking || _isLoading) {
      print('⏳ Auth đang được load, chờ...');
      while (_isChecking || _isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    await checkLoginStatus();
  }

  // Reset state
  void reset() {
    _currentUser = null;
    _isLoading = false;
    _error = null;
    _hasLoaded = false;
    _isChecking = false;
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
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  // THÊM METHOD MỚI: Set user khi đã xác thực từ AuthCheck
  void setAuthenticatedUser(User user) {
    _currentUser = user;
    _isAuthenticated = true;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners(); // Thông báo UI hiển thị loading vòng xoay
    
    try {
      // Gọi logic login từ AuthService
      final user = await AuthService.login(username, password);
      
      if (user != null) {
        // KIỂM TRA PHÂN QUYỀN ADMIN CHO GREENFRUIT MARKET
        if (user.role.toLowerCase() == 'admin') {
          _currentUser = user;
          _isAuthenticated = true;
          _error = null;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          // Trường hợp đăng nhập đúng nhưng là tài khoản khách hàng, không cho vào Admin
          _currentUser = null;
          _isAuthenticated = false;
          _error = 'Tài khoản của bạn không có quyền truy cập trang quản trị.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Đăng nhập thất bại (Dữ liệu trả về null từ AuthService)
        _currentUser = null;
        _isAuthenticated = false;
        // Lấy đúng message "Sai tên đăng nhập hoặc mật khẩu" từ AuthService
        _error = AuthService.lastErrorMessage ?? 'Đăng nhập thất bại.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ AuthProvider Login Exception: $e');
      _error = 'Đã xảy ra lỗi không xác định.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await AuthService.logout();
    } finally {
      _currentUser = null;
      _isAuthenticated = false;
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    try {
      final isAuth = await AuthService.isLoggedIn();
      if (isAuth) {
        final user = await AuthService.getCurrentUser();
        if (user != null && user.role.toLowerCase() == 'admin') {
          _currentUser = user;
          _isAuthenticated = true;
        } else {
          _isAuthenticated = false;
          await AuthService.logout();
        }
      }
    } catch (e) {
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
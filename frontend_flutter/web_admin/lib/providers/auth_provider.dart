import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.login(email, password);
      
      if (user != null && user.role == 'admin') {
        _currentUser = user;
        _isAuthenticated = true;
        _setLoading(false);
        return true;
      } else {
        _setError('Bạn không có quyền truy cập Admin');
        return false;
      }
    } catch (e) {
      _setError('Đăng nhập thất bại');
      return false;
    }
  }
  
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
  
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        final user = await _authService.getCurrentUser();
        if (user != null && user.role == 'admin') {
          _currentUser = user;
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      print('Error checking auth: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
}
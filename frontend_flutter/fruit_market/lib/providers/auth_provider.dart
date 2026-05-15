import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/account_status_service.dart';
import '../models/User.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _hasLoaded = false;
  bool _isChecking = false;
  BuildContext? _context; // THÊM: context để hiển thị dialog

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  String? get token => _currentUser?.token;
  bool get hasLoaded => _hasLoaded;
  bool get isChecking => _isChecking;

  // Constructor - kiểm tra trạng thái đăng nhập khi khởi tạo
  AuthProvider();

  // THÊM: Set context
  void setContext(BuildContext context) {
    _context = context;
  }

  // THÊM: Bắt đầu kiểm tra trạng thái tài khoản định kỳ
  void startAccountStatusCheck() {
    if (isAuthenticated && _context != null) {
      AccountStatusService.init(_context!);
      AccountStatusService.startPeriodicCheck();
      print('✅ Đã bắt đầu kiểm tra trạng thái tài khoản');
    }
  }

  // THÊM: Dừng kiểm tra trạng thái tài khoản
  void stopAccountStatusCheck() {
    AccountStatusService.stopPeriodicCheck();
    print('✅ Đã dừng kiểm tra trạng thái tài khoản');
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
          // THÊM: Nếu đã đăng nhập, bắt đầu kiểm tra định kỳ
          if (_context != null) {
            startAccountStatusCheck();
          }
        }
      }
      
      _hasLoaded = true;
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
        _hasLoaded = true;
        _setLoading(false);
        
        // THÊM: Bắt đầu kiểm tra định kỳ sau khi login thành công
        if (_context != null) {
          startAccountStatusCheck();
        }
        
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
        _hasLoaded = true;
        _setLoading(false);
        
        // THÊM: Bắt đầu kiểm tra định kỳ sau khi đăng ký thành công
        if (_context != null) {
          startAccountStatusCheck();
        }
        
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
    // THÊM: Dừng kiểm tra định kỳ trước khi logout
    stopAccountStatusCheck();
    
    await AuthService.logout();
    _currentUser = null;
    _hasLoaded = false;
    notifyListeners();
    
    print('✅ Đã đăng xuất và dừng kiểm tra tài khoản');
  }

  // THÊM: Kiểm tra trạng thái tài khoản ngay lập tức
  Future<bool> checkAccountStatusNow() async {
    if (!isAuthenticated) return false;
    
    try {
      final response = await ApiService.get('Auth/check-status');
      
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        final data = ApiService.handleResponse(response);
        if (data['code'] == 'ACCOUNT_LOCKED') {
          // Tài khoản bị khóa, logout ngay
          await logout();
          if (_context != null) {
            _showAccountLockedDialog(data['message'] ?? 'Tài khoản của bạn đã bị khóa');
          }
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking account status: $e');
      return true;
    }
  }

  // THÊM: Hiển thị dialog khi tài khoản bị khóa
  void _showAccountLockedDialog(String message) {
    if (_context == null || !_context!.mounted) return;
    
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Tài khoản bị khóa'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(_context!).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Đăng nhập lại'),
          ),
        ],
      ),
    );
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
    stopAccountStatusCheck(); // THÊM: Dừng kiểm tra khi reset
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
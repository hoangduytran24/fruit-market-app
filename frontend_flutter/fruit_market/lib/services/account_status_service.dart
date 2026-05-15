import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_service.dart';

class AccountStatusService {
  static Timer? _checkTimer;
  static BuildContext? _context;
  static bool _isShowingDialog = false;

  static void init(BuildContext context) {
    _context = context;
  }

  static void startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _checkAccountStatus();
    });
    // Kiểm tra ngay lập tức
    _checkAccountStatus();
  }

  static void stopPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  static Future<void> _checkAccountStatus() async {
    final token = await ApiService.getToken();
    if (token == null) return;

    try {
      final response = await ApiService.get('Auth/check-status');
      
      if (response.statusCode == 403) {
        // Đọc trực tiếp thay vì dùng handleResponse
        final data = json.decode(response.body);
        if (data['code'] == 'ACCOUNT_LOCKED') {
          await _handleAccountLocked(data['message'] ?? 'Tài khoản của bạn đã bị khóa');
        }
      }
    } catch (e) {
      print('Error checking account status: $e');
    }
  }

  static Future<void> _handleAccountLocked(String message) async {
    if (_isShowingDialog) return;
    _isShowingDialog = true;
    
    // Dừng kiểm tra
    stopPeriodicCheck();
    
    // Xóa token và user data
    await ApiService.clearAllUserData();
    
    if (_context != null && _context!.mounted) {
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
                _isShowingDialog = false;
                Navigator.of(dialogContext).pop();
                Navigator.of(_context!).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text('Đăng nhập lại'),
            ),
          ],
        ),
      );
    }
  }
}
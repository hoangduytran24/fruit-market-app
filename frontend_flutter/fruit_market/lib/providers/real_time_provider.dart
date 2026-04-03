import 'package:flutter/material.dart';
import '../services/signalr_service.dart';
import '../services/auth_service.dart';
import '../models/real_time_update.dart';

class RealTimeProvider extends ChangeNotifier {
  final SignalRService _signalRService = SignalRService();
  bool _isInitialized = false;
  
  bool get isConnected => _signalRService.isConnected;
  List<RealTimeUpdate> get notifications => _signalRService.notifications;
  
  RealTimeProvider() {
    _signalRService.onNotificationReceived = (update) {
      _handleNotification(update);
    };
  }
  
  Future<void> initialize() async {
    if (_isInitialized && isConnected) return;
    
    final token = await AuthService.getToken();
    final userId = await AuthService.getUserId();
    
    if (token != null && userId != null && token.isNotEmpty) {
      await connect(token, userId);
      _isInitialized = true;
    }
  }
  
  Future<void> connect(String token, String userId) async {
    try {
      await _signalRService.connect(token, userId);
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi kết nối RealTime: $e");
    }
  }

  // Đã khớp với tên hàm trong SignalRService
  Future<void> joinOrderGroup(int orderId) async {
    await _signalRService.joinOrderGroup(orderId);
  }

  Future<void> leaveOrderGroup(int orderId) async {
    await _signalRService.leaveOrderGroup(orderId);
  }
  
  void _handleNotification(RealTimeUpdate update) {
    notifyListeners(); // Cập nhật UI ngay khi nhận tin nhắn mới
  }
  
  Future<void> disconnect() async {
    await _signalRService.disconnect();
    _isInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // KHÔNG dùng await ở đây vì hàm dispose của Service trả về void
    _signalRService.dispose(); 
    super.dispose();
  }
}
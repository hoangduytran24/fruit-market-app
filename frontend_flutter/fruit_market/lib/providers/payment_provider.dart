import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  String? _currentPaymentId;
  String? _qrCodeUrl;
  String _status = 'pending';
  String? _transactionCode;
  String? _errorMessage;
  bool _isLoading = false;
  
  // THÊM: flags để kiểm tra trạng thái
  bool _hasPayment = false;
  bool _isChecking = false;
  String? _currentOrderId;

  // Getters
  String? get currentPaymentId => _currentPaymentId;
  String? get qrCodeUrl => _qrCodeUrl;
  String get status => _status;
  String? get transactionCode => _transactionCode;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasPayment => _hasPayment;
  bool get isChecking => _isChecking;
  bool get isSuccess => _status == 'success';
  bool get isPending => _status == 'pending';
  bool get isFailed => _status == 'failed';

  Future<bool> createVietQRPayment(String orderId, {bool forceRefresh = false}) async {
    if (_hasPayment && _currentOrderId == orderId && !forceRefresh) {
      print('✅ Đã tạo payment cho order $orderId trước đó, bỏ qua');
      return true;
    }
    
    if (_isLoading) {
      print('⏳ Đang tạo payment, bỏ qua request');
      return false;
    }
    
    reset();
    _currentOrderId = orderId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await PaymentService.createVietQRPayment(orderId);
      
      print('Create payment result: $result');
      
      if (result['success'] == true) {
        _currentPaymentId = result['paymentId'];
        _qrCodeUrl = Uri.decodeFull(result['qrCodeUrl']);
        _status = 'pending';
        _hasPayment = true;
        _isLoading = false;
        notifyListeners();
        print('QR Code URL set: $_qrCodeUrl');
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Không thể tạo thanh toán';
        _hasPayment = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error creating payment: $e');
      _errorMessage = 'Lỗi: $e';
      _hasPayment = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Đảm bảo payment đã được tạo
  Future<bool> ensurePaymentCreated(String orderId) async {
    if (_hasPayment && _currentOrderId == orderId) {
      print('✅ Payment đã được tạo trước đó');
      return true;
    }
    
    if (_isLoading) {
      print('⏳ Payment đang được tạo, chờ...');
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _hasPayment;
    }
    
    return await createVietQRPayment(orderId);
  }

  Future<bool> checkPaymentStatus(String orderId) async {
    if (_status == 'success') {
      print('✅ Payment đã thành công trước đó');
      return true;
    }
    
    if (_isChecking) {
      print('⏳ Đang check payment status, bỏ qua request');
      return false;
    }
    
    _isChecking = true;
    notifyListeners();
    
    try {
      final result = await PaymentService.checkPaymentStatus(orderId);
      
      if (result['success'] && result['status'] == 'success') {
        _status = 'success';
        _transactionCode = result['transactionCode'];
        _isChecking = false;
        notifyListeners();
        return true;
      } else if (result['status'] == 'failed') {
        _status = 'failed';
        _errorMessage = result['message'];
        _isChecking = false;
        notifyListeners();
        return false;
      } else {
        _isChecking = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi: $e';
      _isChecking = false;
      notifyListeners();
      return false;
    }
  }

  // Kiểm tra trạng thái định kỳ (polling)
  Future<void> startPolling(String orderId, {int intervalSeconds = 3, int maxAttempts = 10}) async {
    int attempts = 0;
    while (attempts < maxAttempts && _status == 'pending' && _hasPayment) {
      await Future.delayed(Duration(seconds: intervalSeconds));
      if (_status == 'pending') {
        await checkPaymentStatus(orderId);
        attempts++;
      }
    }
  }

  // Reset state
  void reset() {
    _currentPaymentId = null;
    _qrCodeUrl = null;
    _status = 'pending';
    _transactionCode = null;
    _errorMessage = null;
    _isLoading = false;
    _hasPayment = false;
    _isChecking = false;
    _currentOrderId = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set status manually
  void setStatus(String status) {
    _status = status;
    notifyListeners();
  }

  // Set QR code URL
  void setQrCodeUrl(String url) {
    _qrCodeUrl = url;
    notifyListeners();
  }

  // Kiểm tra xem có payment cho order này không
  bool hasPaymentForOrder(String orderId) {
    return _hasPayment && _currentOrderId == orderId;
  }
}
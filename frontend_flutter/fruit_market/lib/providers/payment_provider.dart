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
  
  // THÊM: phân biệt loại thanh toán
  String _paymentMethod = 'vietqr'; // 'vietqr' hoặc 'sepay'

  // Getters
  String? get currentPaymentId => _currentPaymentId;
  String? get qrCodeUrl => _qrCodeUrl;
  String get status => _status;
  String? get transactionCode => _transactionCode;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasPayment => _hasPayment;
  bool get isChecking => _isChecking;
  bool get isSuccess => _status == 'success' || _status == 'paid';
  bool get isPending => _status == 'pending';
  bool get isFailed => _status == 'failed';
  String get paymentMethod => _paymentMethod;

  // ==================== THÊM CÁC METHOD MỚI ====================

  /// Set payment ID manually (dùng khi load payment cũ)
  void setPaymentId(String paymentId) {
    _currentPaymentId = paymentId;
    _hasPayment = true;
    notifyListeners();
  }

  /// Set status manually (dùng khi load payment cũ)
  void setStatus(String status) {
    _status = status;
    notifyListeners();
  }

  /// Set QR code URL manually (dùng khi load payment cũ)
  void setQrCodeUrl(String url) {
    _qrCodeUrl = url;
    _hasPayment = true;
    notifyListeners();
  }

  /// Set order ID manually
  void setCurrentOrderId(String orderId) {
    _currentOrderId = orderId;
    notifyListeners();
  }

  /// Set payment method manually
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  /// Set transaction code
  void setTransactionCode(String code) {
    _transactionCode = code;
    notifyListeners();
  }

  /// Load existing payment từ paymentId (không tạo mới)
  Future<bool> loadExistingPayment(String paymentId, {String orderId = ''}) async {
    if (_isLoading) {
      print('⏳ Đang loading, bỏ qua request');
      return false;
    }
    
    // Không reset state, chỉ cập nhật
    _isLoading = true;
    _errorMessage = null;
    if (orderId.isNotEmpty) {
      _currentOrderId = orderId;
    }
    notifyListeners();

    try {
      final result = await PaymentService.getPaymentInfo(paymentId);
      
      print('Load existing payment result: $result');
      
      if (result['success'] == true) {
        final data = result['data'];
        
        _currentPaymentId = data['paymentId'];
        _qrCodeUrl = data['qrCodeUrl'];
        _hasPayment = true;
        
        if (data['paymentStatus'] == 'paid') {
          _status = 'paid';
          _transactionCode = data['transactionCode'];
        } else {
          _status = 'pending';
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Không thể tải thông tin thanh toán';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error loading existing payment: $e');
      _errorMessage = 'Lỗi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== SEPAY ====================

  /// Tạo thanh toán với SePay
  Future<bool> createSePayPayment(String orderId, {bool forceRefresh = false}) async {
    if (_hasPayment && _currentOrderId == orderId && !forceRefresh) {
      print('✅ Đã tạo SePay payment cho order $orderId trước đó, bỏ qua');
      return true;
    }
    
    if (_isLoading) {
      print('⏳ Đang tạo payment, bỏ qua request');
      return false;
    }
    
    reset();
    _currentOrderId = orderId;
    _paymentMethod = 'sepay';
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await PaymentService.createSePayPayment(orderId);
      
      print('Create SePay payment result: $result');
      
      if (result['success'] == true) {
        _currentPaymentId = result['paymentId'];
        _qrCodeUrl = result['qrCodeUrl'];
        _status = 'pending';
        _hasPayment = true;
        _isLoading = false;
        notifyListeners();
        print('QR Code URL set: $_qrCodeUrl');
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Không thể tạo thanh toán SePay';
        _hasPayment = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error creating SePay payment: $e');
      _errorMessage = 'Lỗi: $e';
      _hasPayment = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Kiểm tra trạng thái thanh toán SePay
  Future<bool> checkSePayPaymentStatus(String orderId) async {
    if (_status == 'paid' || _status == 'success') {
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
      final result = await PaymentService.checkSePayPaymentStatus(orderId);
      
      print('Check SePay payment status result: $result');
      
      if (result['success'] == true && result['status'] == 'paid') {
        _status = 'paid';
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
      print('Error checking SePay payment: $e');
      _errorMessage = 'Lỗi: $e';
      _isChecking = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== VIETQR (GIỮ LẠI) ====================

  /// Tạo thanh toán VietQR
  Future<bool> createVietQRPayment(String orderId, {bool forceRefresh = false}) async {
    if (_hasPayment && _currentOrderId == orderId && !forceRefresh) {
      print('✅ Đã tạo VietQR payment cho order $orderId trước đó, bỏ qua');
      return true;
    }
    
    if (_isLoading) {
      print('⏳ Đang tạo payment, bỏ qua request');
      return false;
    }
    
    reset();
    _currentOrderId = orderId;
    _paymentMethod = 'vietqr';
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await PaymentService.createVietQRPayment(orderId);
      
      print('Create VietQR payment result: $result');
      
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

  /// Kiểm tra trạng thái thanh toán VietQR
  Future<bool> checkVietQRPaymentStatus(String orderId) async {
    if (_status == 'success') {
      print('Payment đã thành công trước đó');
      return true;
    }
    
    if (_isChecking) {
      print('⏳ Đang check payment status, bỏ qua request');
      return false;
    }
    
    _isChecking = true;
    notifyListeners();
    
    try {
      final result = await PaymentService.checkVietQRPaymentStatus(orderId);
      
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

  // ==================== METHOD CHUNG ====================

  /// Tạo payment theo phương thức được chọn
  Future<bool> createPayment(String orderId, {String method = 'sepay', bool forceRefresh = false}) async {
    if (method == 'sepay') {
      return await createSePayPayment(orderId, forceRefresh: forceRefresh);
    } else {
      return await createVietQRPayment(orderId, forceRefresh: forceRefresh);
    }
  }

  /// Kiểm tra trạng thái theo phương thức đã chọn
  Future<bool> checkPaymentStatus(String orderId) async {
    if (_paymentMethod == 'sepay') {
      return await checkSePayPaymentStatus(orderId);
    } else {
      return await checkVietQRPaymentStatus(orderId);
    }
  }

  /// Đảm bảo payment đã được tạo
  Future<bool> ensurePaymentCreated(String orderId, {String method = 'sepay'}) async {
    if (_hasPayment && _currentOrderId == orderId && _paymentMethod == method) {
      print('Payment đã được tạo trước đó');
      return true;
    }
    
    if (_isLoading) {
      print('Payment đang được tạo, chờ...');
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _hasPayment;
    }
    
    return await createPayment(orderId, method: method);
  }

  /// Bắt đầu polling (kiểm tra định kỳ) - CHỈ DÙNG CHO TẠO MỚI
  Future<void> startPolling(String orderId, {int intervalSeconds = 3, int maxAttempts = 60}) async {
    int attempts = 0;
    while (attempts < maxAttempts && isPending && _hasPayment) {
      await Future.delayed(Duration(seconds: intervalSeconds));
      if (isPending) {
        await checkPaymentStatus(orderId);
        attempts++;
        print('🔄 Polling lần $attempts/$maxAttempts - Status: $_status');
      }
    }
  }

  /// Reset state
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
    _paymentMethod = 'vietqr';
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Kiểm tra xem có payment cho order này không
  bool hasPaymentForOrder(String orderId) {
    return _hasPayment && _currentOrderId == orderId;
  }
  
  /// Kiểm tra xem có đang dùng SePay không
  bool get isSePay => _paymentMethod == 'sepay';
  
  /// Kiểm tra xem có đang dùng VietQR không
  bool get isVietQR => _paymentMethod == 'vietqr';
}
import 'dart:async';
import 'dart:convert';
import 'api_service.dart';

class PaymentService {
  // ==================== SEPAY ====================

  /// Tạo thanh toán với SePay (hiển thị QR)
  static Future<Map<String, dynamic>> createSePayPayment(String orderId) async {
    try {
      final response = await ApiService.post('Payment/sepay/create', body: {
        'orderId': orderId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'paymentId': data['paymentId'],
          'qrCodeUrl': data['qrCodeUrl'],
          'amount': data['amount'],
          'orderId': data['orderId'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'Lỗi: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  /// Kiểm tra trạng thái thanh toán SePay (polling)
  static Future<Map<String, dynamic>> checkSePayPaymentStatus(String orderId) async {
    try {
      final response = await ApiService.get('Payment/sepay/status/$orderId');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'status': 'error',
          'message': 'Lỗi: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'status': 'error',
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  /// Lấy thông tin chi tiết payment
  static Future<Map<String, dynamic>> getPaymentInfo(String paymentId) async {
    try {
      final response = await ApiService.get('Payment/info/$paymentId');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Lỗi: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // ==================== VIETQR (Giữ lại nếu cần) ====================

  /// Tạo thanh toán VietQR (cũ)
  static Future<Map<String, dynamic>> createVietQRPayment(String orderId) async {
    try {
      final response = await ApiService.post('Payment/vietqr/create', body: {
        'orderId': orderId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Lỗi: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  /// Kiểm tra trạng thái thanh toán VietQR (cũ)
  static Future<Map<String, dynamic>> checkVietQRPaymentStatus(String orderId) async {
    try {
      final response = await ApiService.get('Payment/vietqr/check/$orderId');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'status': 'error',
          'message': 'Lỗi: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'status': 'error',
        'message': 'Lỗi kết nối: $e',
      };
    }
  }
}
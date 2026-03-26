import 'dart:convert';
import 'api_service.dart';

class PaymentService {
  // Tạo thanh toán VietQR
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

  // Kiểm tra trạng thái thanh toán
  static Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async {
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
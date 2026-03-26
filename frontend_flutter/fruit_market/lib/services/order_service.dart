import 'dart:convert';
import 'api_service.dart';
import '../models/Order.dart';

class OrderService {
  // Lấy danh sách đơn hàng của user
  Future<List<Order>> getUserOrders() async {
    try {
      final response = await ApiService.get('orders');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Order.fromJson(e)).toList();
      } else {
        throw Exception('Không thể tải danh sách đơn hàng');
      }
    } catch (e) {
      print('❌ Get user orders error: $e');
      rethrow;
    }
  }

  // Lấy chi tiết đơn hàng
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await ApiService.get('orders/$orderId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data);
      } else {
        throw Exception('Không thể tải chi tiết đơn hàng');
      }
    } catch (e) {
      print('❌ Get order by id error: $e');
      rethrow;
    }
  }

  // Mua ngay
  Future<Order> buyNow({
    required String productId,
    required int quantity,
    required String paymentMethod,
    required String deliveryAddress,
    String? voucherCode,
    double shippingFee = 25000, // ✅ Thêm tham số
  }) async {
    try {
      final response = await ApiService.post(
        'orders/buy-now',
        body: {
          'productId': productId,
          'quantity': quantity,
          'paymentMethod': paymentMethod,
          'deliveryAddress': deliveryAddress,
          'voucherCode': voucherCode,
          'shippingFee': shippingFee, // ✅ Thêm dòng này
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể tạo đơn hàng');
      }
    } catch (e) {
      print('❌ Buy now error: $e');
      rethrow;
    }
  }

  // Tạo đơn từ giỏ hàng
  Future<Order> createOrderFromCart({
    required String deliveryAddress,
    required String paymentMethod,
    String? voucherCode,
    double shippingFee = 25000, // ✅ Thêm tham số
  }) async {
    try {
      final response = await ApiService.post(
        'orders',
        body: {
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
          'voucherCode': voucherCode,
          'shippingFee': shippingFee, // ✅ Thêm dòng này
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể tạo đơn hàng');
      }
    } catch (e) {
      print('❌ Create order from cart error: $e');
      rethrow;
    }
  }

  // Hủy đơn hàng
  Future<bool> cancelOrder(String orderId) async {
    try {
      final response = await ApiService.post('orders/$orderId/cancel');
      
      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể hủy đơn hàng');
      }
    } catch (e) {
      print('❌ Cancel order error: $e');
      rethrow;
    }
  }
}
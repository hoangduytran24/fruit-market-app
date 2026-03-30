import 'dart:convert';
import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  /// Lấy danh sách đơn hàng cho Admin (có lọc theo trạng thái hoặc lấy tất cả)
  Future<List<OrderListDto>> getAllOrders({String? status}) async {
    try {
      // Khớp với Route: [HttpGet("admin/all")] hoặc [HttpGet("admin/status/{status}")]
      String endpoint = (status != null && status != 'Tất cả' && status.isNotEmpty)
          ? 'Orders/admin/status/$status'
          : 'Orders/admin/all';

      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => OrderListDto.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error in getAllOrders: $e');
      return [];
    }
  }
  
  /// Lấy chi tiết đơn hàng theo ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final response = await ApiService.get('Orders/$orderId');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error in getOrderById: $e');
      return null;
    }
  }
  
  /// Cập nhật trạng thái đơn hàng - Khớp với UpdateOrderStatusDto của Backend
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      // Backend yêu cầu UpdateOrderStatusDto { string Status }
      // ApiService.put sẽ nhận Map này và gửi đi dưới dạng JSON
      final response = await ApiService.put(
        'Orders/$orderId/status',
        body: {'status': status}, 
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Server returned ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Connection Error: $e');
      return false;
    }
  }

  /// Hủy đơn hàng (Post request tới [HttpPost("{id}/cancel")])
  Future<bool> cancelOrder(String orderId) async {
    try {
      final response = await ApiService.post('Orders/$orderId/cancel');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error in cancelOrder: $e');
      return false;
    }
  }
}
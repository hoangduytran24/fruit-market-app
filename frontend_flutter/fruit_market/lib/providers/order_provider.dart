import 'package:flutter/material.dart';
import '../models/Order.dart';  // SỬA: import Order.dart (viết hoa)
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;
  
  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Lấy danh sách đơn hàng
  Future<bool> fetchMyOrders() async {
    _setLoading(true);
    _clearError();
    
    try {
      _orders = await _orderService.getUserOrders();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
  
  // Lấy chi tiết đơn hàng
  Future<Order?> fetchOrderDetail(String orderId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentOrder = await _orderService.getOrderById(orderId);
      _setLoading(false);
      return _currentOrder;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }
  
  // Mua ngay
  Future<Order?> buyNow({
    required String productId,
    required int quantity,
    required String paymentMethod,
    required String deliveryAddress,
    String? voucherCode,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final order = await _orderService.buyNow(
        productId: productId,
        quantity: quantity,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        voucherCode: voucherCode,
      );
      _setLoading(false);
      return order;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }
  
  // Tạo đơn từ giỏ hàng
  Future<Order?> createOrderFromCart({
    required String deliveryAddress,
    required String paymentMethod,
    String? voucherCode,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final order = await _orderService.createOrderFromCart(
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        voucherCode: voucherCode,
      );
      _setLoading(false);
      return order;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }
  
  // Hủy đơn hàng
  Future<bool> cancelOrder(String orderId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _orderService.cancelOrder(orderId);
      _setLoading(false);
      if (success) {
        await fetchMyOrders();
      }
      return success;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void reset() {
    _orders = [];
    _currentOrder = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
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
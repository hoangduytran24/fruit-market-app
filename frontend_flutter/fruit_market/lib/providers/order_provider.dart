import 'package:flutter/material.dart';
import '../models/Order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;
  bool _hasLoaded = false; // THÊM
  bool _isFetching = false; // THÊM

  // Getters
  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _hasLoaded; // THÊM
  bool get isFetching => _isFetching; // THÊM
  bool get hasOrders => _orders.isNotEmpty; // THÊM
  
  // Lấy danh sách đơn hàng
  Future<bool> fetchMyOrders({bool forceRefresh = false}) async {
    // Nếu đang fetch thì bỏ qua
    if (_isFetching) {
      print('⏳ Đang fetch orders, bỏ qua request');
      return false;
    }
    
    // Nếu đã load và không force refresh thì bỏ qua
    if (_hasLoaded && !forceRefresh && _orders.isNotEmpty) {
      print('✅ Đã load orders trước đó, bỏ qua fetch');
      return true;
    }

    _isFetching = true;
    _setLoading(true);
    _clearError();
    
    try {
      _orders = await _orderService.getUserOrders();
      _hasLoaded = true; // THÊM
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _isFetching = false;
      _setLoading(false);
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
  
  // Đảm bảo orders đã được load
  Future<void> ensureOrdersLoaded() async {
    if (_hasLoaded && _orders.isNotEmpty) {
      print('✅ Orders đã được load trước đó');
      return;
    }
    
    if (_isFetching || _isLoading) {
      print('⏳ Orders đang được load, chờ...');
      while (_isFetching || _isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    await fetchMyOrders();
  }
  
  // THÊM: Load orders silently (không set loading state)
  Future<void> loadOrdersSilently() async {
    if (_hasLoaded) return;
    
    try {
      _orders = await _orderService.getUserOrders();
      _hasLoaded = true;
      notifyListeners();
    } catch (e) {
      print('❌ Load orders silently error: $e');
    }
  }
  
  // Mua ngay
  Future<Order?> buyNow({
    required String productId,
    required int quantity,
    required String paymentMethod,
    required String deliveryAddress,
    String? voucherCode,
    double shippingFee = 25000,
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
        shippingFee: shippingFee,
      );
      // THÊM: refresh orders sau khi mua thành công
      if (order != null) {
        await fetchMyOrders(forceRefresh: true);
      }
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
    double shippingFee = 25000,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final order = await _orderService.createOrderFromCart(
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        voucherCode: voucherCode,
        shippingFee: shippingFee,
      );
      // THÊM: refresh orders sau khi tạo thành công
      if (order != null) {
        await fetchMyOrders(forceRefresh: true);
      }
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
        // THÊM: force refresh sau khi hủy
        await fetchMyOrders(forceRefresh: true);
      }
      return success;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
  
  // THÊM: Làm mới dữ liệu (force refresh)
  Future<bool> refreshOrders() async {
    return await fetchMyOrders(forceRefresh: true);
  }
  
  // THÊM: Lấy đơn hàng theo trạng thái
  List<Order> getOrdersByStatus(String status) {
    if (status == 'all') return _orders;
    return _orders.where((order) => order.status == status).toList();
  }
  
  // THÊM: Thống kê số lượng đơn hàng theo trạng thái
  Map<String, int> getOrderStatistics() {
    return {
      'pending': _orders.where((o) => o.status == 'pending').length,
      'shipping': _orders.where((o) => o.status == 'shipping').length,
      'delivered': _orders.where((o) => o.status == 'delivered').length,
      'cancelled': _orders.where((o) => o.status == 'cancelled').length,
      'total': _orders.length,
    };
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
    _hasLoaded = false;
    _isFetching = false;
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
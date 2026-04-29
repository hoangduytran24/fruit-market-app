import 'package:flutter/material.dart';
import '../models/Order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;
  bool _hasLoaded = false;
  bool _isFetching = false;

  // Getters
  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _hasLoaded;
  bool get isFetching => _isFetching;
  bool get hasOrders => _orders.isNotEmpty;
  
  // --- Lấy danh sách đơn hàng ---
  Future<bool> fetchMyOrders({bool forceRefresh = false}) async {
    if (_isFetching) return false;
    
    if (_hasLoaded && !forceRefresh && _orders.isNotEmpty) {
      return true;
    }

    _isFetching = true;
    if (_orders.isEmpty || forceRefresh) _setLoading(true);
    _clearError();
    
    try {
      final updatedOrders = await _orderService.getUserOrders();
      _orders = List.from(updatedOrders); 
      _hasLoaded = true;
      notifyListeners();
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
      notifyListeners();
      return _currentOrder;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // --- CÁC HÀM QUAN TRỌNG CHO CHECKOUT ---

  // Mua ngay
  Future<Order?> buyNow({
    required String productId,
    required int quantity,
    required String paymentMethod,
    required String deliveryAddress,
    required String receiverName,      // Thêm
    required String receiverPhone,     // Thêm
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
        receiverName: receiverName,      // Thêm
        receiverPhone: receiverPhone,    // Thêm
        voucherCode: voucherCode,
        shippingFee: shippingFee,
      );
      await fetchMyOrders(forceRefresh: true);
      return order;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Tạo đơn từ giỏ hàng
  Future<Order?> createOrderFromCart({
    required String deliveryAddress,
    required String paymentMethod,
    required String receiverName,      // Thêm
    required String receiverPhone,     // Thêm
    String? voucherCode,
    double shippingFee = 25000,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final order = await _orderService.createOrderFromCart(
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        receiverName: receiverName,      // Thêm
        receiverPhone: receiverPhone,    // Thêm
        voucherCode: voucherCode,
        shippingFee: shippingFee,
      );
      await fetchMyOrders(forceRefresh: true);
      return order;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Hủy đơn hàng
  Future<bool> cancelOrder(String orderId) async {
    _setLoading(true);
    _clearError();
    try {
      final success = await _orderService.cancelOrder(orderId);
      if (success) {
        await fetchMyOrders(forceRefresh: true);
      }
      return success;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Các phương thức khác
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
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
}
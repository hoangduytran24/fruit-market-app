import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<OrderListDto> _allFilteredOrders = []; // Danh sách gốc từ server
  List<OrderListDto> _orders = [];            // Danh sách hiển thị trên trang hiện tại
  bool _isLoading = false;
  String? _filterStatus;
  String? _searchKeyword;
  
  int _currentPage = 1;
  static const int _pageSize = 9;

  // Getters
  List<OrderListDto> get orders => _orders;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get totalPages => (_allFilteredOrders.length / _pageSize).ceil() == 0 
      ? 1 
      : (_allFilteredOrders.length / _pageSize).ceil();

  /// Tải dữ liệu và xử lý search/filter
  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final results = await _orderService.getAllOrders(status: _filterStatus);
      
      if (_searchKeyword != null && _searchKeyword!.isNotEmpty) {
        _allFilteredOrders = results.where((o) => 
          o.orderId.toLowerCase().contains(_searchKeyword!.toLowerCase())
        ).toList();
      } else {
        _allFilteredOrders = results;
      }

      _paginate();
    } catch (e) {
      print("❌ Fetch Orders Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Chia nhỏ danh sách theo trang (Pagination)
  void _paginate() {
    final int start = (_currentPage - 1) * _pageSize;
    int end = start + _pageSize;
    if (end > _allFilteredOrders.length) end = _allFilteredOrders.length;
    
    _orders = (start < _allFilteredOrders.length) 
        ? _allFilteredOrders.sublist(start, end) 
        : [];
  }

  /// Cập nhật trạng thái đơn hàng
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final success = await _orderService.updateOrderStatus(orderId, status);
      
      if (success) {
        // Vì status trong Model là 'final', ta không gán trực tiếp được.
        // Giải pháp chuẩn: Tải lại dữ liệu từ Server để đồng bộ UI chính xác 100%
        await fetchOrders(); 
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Update Status Error: $e");
      return false;
    }
  }

  // --- Các hàm điều khiển giao diện ---

  void goToPage(int page) {
    _currentPage = page;
    _paginate();
    notifyListeners();
  }

  void searchOrders(String keyword) {
    _searchKeyword = keyword.trim();
    _currentPage = 1;
    fetchOrders();
  }

  void filterByStatus(String? status) {
    _filterStatus = status;
    _currentPage = 1;
    fetchOrders();
  }

  Future<void> refreshOrders() async {
    _currentPage = 1;
    await fetchOrders();
  }

  Future<Order?> getOrderById(String orderId) => _orderService.getOrderById(orderId);
}
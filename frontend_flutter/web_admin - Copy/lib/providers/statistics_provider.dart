import 'package:flutter/material.dart';
import '../models/statistics.dart';
import '../services/statistics_service.dart';

class AdminStatisticsProvider extends ChangeNotifier {
  DashboardStats? _dashboard;
  List<TopProduct> _topProducts = [];
  List<RevenueData> _revenueList = [];
  OrderStatusStats? _orderStatus;
  OrderStats? _orderStats;  // Thay thế UserStats
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DashboardStats? get dashboard => _dashboard;
  List<TopProduct> get topProducts => _topProducts;
  List<RevenueData> get revenueList => _revenueList;
  OrderStatusStats? get orderStatus => _orderStatus;
  OrderStats? get orderStats => _orderStats;  // Thay thế userStats
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Tải TOÀN BỘ dữ liệu (5 API) cho trang Dashboard
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi đồng thời cả 5 API để tối ưu tốc độ load
      final results = await Future.wait([
        StatisticsService.getDashboardStatistics(),    // results[0]
        StatisticsService.getTopProducts(top: 6, period: 'month'), // results[1]
        StatisticsService.getRevenueStatistics(period: 'day'),   // results[2]
        StatisticsService.getOrderStatusStatistics(),   // results[3]
        StatisticsService.getOrderStatistics(),         // results[4] - Thay đổi
      ]);

      _dashboard = results[0] as DashboardStats?;
      _topProducts = results[1] as List<TopProduct>;
      _revenueList = results[2] as List<RevenueData>;
      _orderStatus = results[3] as OrderStatusStats?;
      _orderStats = results[4] as OrderStats?;  // Thay đổi

      if (_dashboard == null) {
        _errorMessage = "Không thể tải dữ liệu thống kê tổng quan.";
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối máy chủ. Vui lòng thử lại.";
      debugPrint("AdminStatisticsProvider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật riêng lẻ từng phần nếu cần (ví dụ khi Admin chọn filter khác)
  Future<void> loadRevenueData(String period) async {
    _revenueList = await StatisticsService.getRevenueStatistics(period: period);
    notifyListeners();
  }

  Future<void> loadTopProducts({int top = 10, String period = 'month'}) async {
    _topProducts = await StatisticsService.getTopProducts(top: top, period: period);
    notifyListeners();
  }

  Future<void> loadOrderStatusData() async {
    _orderStatus = await StatisticsService.getOrderStatusStatistics();
    notifyListeners();
  }

  Future<void> loadOrderStatsData() async {
    _orderStats = await StatisticsService.getOrderStatistics();
    notifyListeners();
  }

  void clearData() {
    _dashboard = null;
    _topProducts = [];
    _revenueList = [];
    _orderStatus = null;
    _orderStats = null;
    _errorMessage = null;
    notifyListeners();
  }
}
import 'package:flutter/material.dart';
import '../models/statistics.dart';
import '../services/statistics_service.dart';

class AdminStatisticsProvider extends ChangeNotifier {
  DashboardStats? _dashboard;
  List<TopProduct> _topProducts = [];
  List<RevenueData> _revenueList = [];
  OrderStatusStats? _orderStatus; // Dữ liệu mới từ Backend
  UserStats? _userStats;         // Dữ liệu mới từ Backend
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DashboardStats? get dashboard => _dashboard;
  List<TopProduct> get topProducts => _topProducts;
  List<RevenueData> get revenueList => _revenueList;
  OrderStatusStats? get orderStatus => _orderStatus;
  UserStats? get userStats => _userStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Tải TOÀN BỘ dữ liệu (5 API) cho trang Dashboard của GreenFruit Market
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
        StatisticsService.getUserStatistics(),          // results[4]
      ]);

      _dashboard = results[0] as DashboardStats?;
      _topProducts = results[1] as List<TopProduct>;
      _revenueList = results[2] as List<RevenueData>;
      _orderStatus = results[3] as OrderStatusStats?;
      _userStats = results[4] as UserStats?;

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

  Future<void> loadUserStatsData() async {
    _userStats = await StatisticsService.getUserStatistics();
    notifyListeners();
  }

  void clearData() {
    _dashboard = null;
    _topProducts = [];
    _revenueList = [];
    _orderStatus = null;
    _userStats = null;
    _errorMessage = null;
    notifyListeners();
  }
}
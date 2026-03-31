import 'dart:convert';
import '../models/statistics.dart';
import 'api_service.dart';

class StatisticsService {
  // 1. GET: api/Statistics/dashboard
  static Future<DashboardStats?> getDashboardStatistics() async {
    try {
      final response = await ApiService.get('Statistics/dashboard');
      if (response.statusCode == 200) {
        return DashboardStats.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Lỗi StatisticsService.getDashboardStatistics: $e');
      return null;
    }
  }

  // 2. GET: api/Statistics/top-products?top=...&period=...
  static Future<List<TopProduct>> getTopProducts({int top = 5, String period = 'month'}) async {
    try {
      final response = await ApiService.get('Statistics/top-products?top=$top&period=$period');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => TopProduct.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi StatisticsService.getTopProducts: $e');
      return [];
    }
  }

  // 3. GET: api/Statistics/revenue?period=...
  static Future<List<RevenueData>> getRevenueStatistics({String period = 'day'}) async {
    try {
      final response = await ApiService.get('Statistics/revenue?period=$period');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => RevenueData.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi StatisticsService.getRevenueStatistics: $e');
      return [];
    }
  }

  // 4. GET: api/Statistics/order-status
  static Future<OrderStatusStats?> getOrderStatusStatistics() async {
    try {
      final response = await ApiService.get('Statistics/order-status');
      if (response.statusCode == 200) {
        return OrderStatusStats.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Lỗi StatisticsService.getOrderStatusStatistics: $e');
      return null;
    }
  }

  // 5. GET: api/Statistics/orders (Mới)
  static Future<OrderStats?> getOrderStatistics() async {
    try {
      final response = await ApiService.get('Statistics/orders');
      if (response.statusCode == 200) {
        return OrderStats.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Lỗi StatisticsService.getOrderStatistics: $e');
      return null;
    }
  }
}
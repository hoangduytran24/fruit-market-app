import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ReturnRequest.dart';
import '../services/api_service.dart';

class ReturnProvider extends ChangeNotifier {
  List<ReturnRequest> _returns = [];
  ReturnRequest? _currentReturn;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentFilterStatus = 'all';

  List<ReturnRequest> get returns => _returns;
  ReturnRequest? get currentReturn => _currentReturn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilterStatus => _currentFilterStatus;

  /// Lấy tất cả yêu cầu trả hàng (Admin)
  Future<void> fetchAllReturnRequests({String? status}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String endpoint = status != null && status != 'all'
          ? 'Return/all?status=$status'
          : 'Return/all';
      
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          _returns = list.map((e) => ReturnRequest.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print('Lỗi fetch all returns: $e');
      _errorMessage = 'Không thể tải danh sách yêu cầu trả hàng';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lọc theo trạng thái
  void filterReturnsByStatus(String status) {
    _currentFilterStatus = status;
    fetchAllReturnRequests(status: status == 'all' ? null : status);
  }

  /// Lấy chi tiết yêu cầu trả hàng
  Future<ReturnRequest?> fetchReturnDetail(String returnId) async {
    try {
      final response = await ApiService.get('Return/detail/$returnId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _currentReturn = ReturnRequest.fromJson(data['data']);
          notifyListeners();
          return _currentReturn;
        }
      }
      return null;
    } catch (e) {
      print('Lỗi fetch return detail: $e');
      return null;
    }
  }

  /// Xử lý yêu cầu (duyệt/từ chối)
  Future<bool> processReturnRequest({
    required String returnId,
    required bool isApproved,
    String? rejectReason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('Return/process', body: {
        'returnId': returnId,
        'isApproved': isApproved,
        'rejectReason': rejectReason,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isLoading = false;
        notifyListeners();
        return data['success'] == true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Lỗi process return: $e');
      _errorMessage = 'Xử lý thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Xác nhận đã nhận lại hàng và hoàn tiền
  Future<bool> completeReturnRequest(String returnId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('Return/complete/$returnId');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isLoading = false;
        notifyListeners();
        return data['success'] == true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Lỗi complete return: $e');
      _errorMessage = 'Xác nhận thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Lấy returnId theo orderId
  Future<String?> getReturnIdByOrderId(String orderId) async {
    try {
      final response = await ApiService.get('Return/by-order/$orderId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['returnId'];
      }
      return null;
    } catch (e) {
      print('Lỗi lấy returnId: $e');
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _returns = [];
    _currentReturn = null;
    _errorMessage = null;
    _isLoading = false;
    _currentFilterStatus = 'all';
    notifyListeners();
  }
}
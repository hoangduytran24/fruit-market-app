import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/ReturnRequest.dart';
import '../services/api_service.dart';

class ReturnProvider extends ChangeNotifier {
  List<ReturnRequest> _returns = [];
  ReturnRequest? _currentReturn;
  bool _isLoading = false;
  String? _errorMessage;

  List<ReturnRequest> get returns => _returns;
  ReturnRequest? get currentReturn => _currentReturn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Kiểm tra đơn hàng có được trả không
  Future<bool> canReturnOrder(String orderId) async {
    try {
      print('=== CAN RETURN ORDER API ===');
      print('Calling: Return/can-return/$orderId');
      
      final response = await ApiService.get('Return/can-return/$orderId');
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['canReturn'] ?? false;
        print('canReturn result: $result');
        return result;
      }
      print('Returning false due to status code: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Lỗi kiểm tra trả hàng: $e');
      return false;
    }
  }

  /// Tạo yêu cầu trả hàng (HỖ TRỢ UPLOAD ẢNH)
  Future<bool> createReturnRequest({
    required String orderId,
    required String reason,
    String? description,
    String? imageUrl,
    File? imageFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Chuẩn bị fields
      final fields = <String, String>{
        'OrderId': orderId,
        'Reason': reason,
      };
      
      if (description != null && description.isNotEmpty) {
        fields['Description'] = description;
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        fields['ImageUrl'] = imageUrl;
      }
      
      print('=== CREATE RETURN REQUEST WITH IMAGE ===');
      print('OrderId: $orderId');
      print('Reason: $reason');
      print('Has image: ${imageFile != null}');
      print('URL: ${ApiService.baseUrl}Return/create');
      
      // Dùng phương thức postMultipart từ ApiService
      final response = await ApiService.postMultipart(
        'Return/create',
        fields: fields,
        imageFile: imageFile,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _currentReturn = ReturnRequest.fromJson(data['data']);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = data['message'] ?? 'Không thể tạo yêu cầu';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Lỗi: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Lấy danh sách yêu cầu trả hàng của tôi
  Future<void> fetchMyReturns() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('Return/my-returns');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          _returns = list.map((e) => ReturnRequest.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print('Lỗi fetch returns: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  /// Lấy returnId theo orderId
  Future<String?> getReturnIdByOrderId(String orderId) async {
    try {
      print('=== GET RETURN ID BY ORDER ID ===');
      print('Calling: Return/by-order/$orderId');
      
      final response = await ApiService.get('Return/by-order/$orderId');
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final returnId = data['returnId'];
        print('ReturnId: $returnId');
        return returnId;
      }
      return null;
    } catch (e) {
      print('Lỗi lấy returnId: $e');
      return null;
    }
  }

  /// Hủy yêu cầu trả hàng
  Future<bool> cancelReturnRequest(String returnId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('Return/cancel/$returnId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isLoading = false;
        notifyListeners();
        
        if (data['success'] == true) {
          _returns.removeWhere((r) => r.returnId == returnId);
          notifyListeners();
          return true;
        }
        return false;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _currentReturn = null;
    _errorMessage = null;
    notifyListeners();
  }
}
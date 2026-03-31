import 'package:flutter/material.dart';
import '../services/supplier_service.dart';
import '../models/supplier.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierService _supplierService = SupplierService();
  
  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  String? _error;

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Lấy danh sách nhà cung cấp
  Future<void> fetchSuppliers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _suppliers = await _supplierService.getSuppliers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Thêm mới
  Future<bool> createSupplier({
    required String supplierName,
    String? address,
    String? phone,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _supplierService.createSupplier(
        supplierName: supplierName,
        address: address,
        phone: phone,
        email: email,
      );
      
      if (result != null) {
        await fetchSuppliers(); // Load lại danh sách sau khi thêm thành công
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật
  Future<bool> updateSupplier({
    required String supplierId,
    required String supplierName,
    String? address,
    String? phone,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _supplierService.updateSupplier(
        supplierId: supplierId,
        supplierName: supplierName,
        address: address,
        phone: phone,
        email: email,
      );
      
      if (result != null) {
        await fetchSuppliers(); // Load lại danh sách sau khi sửa thành công
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xóa
  Future<bool> deleteSupplier(String supplierId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _supplierService.deleteSupplier(supplierId);
      if (success) {
        await fetchSuppliers();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
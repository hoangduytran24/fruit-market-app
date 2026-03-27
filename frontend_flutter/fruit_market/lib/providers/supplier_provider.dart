import 'package:flutter/material.dart';
import '../models/Supplier.dart';
import '../services/supplier_service.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierService _supplierService = SupplierService();
  
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  // Getters
  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  // Lấy danh sách nhà cung cấp
  Future<void> fetchSuppliers({bool forceRefresh = false}) async {
    if (_hasLoaded && !forceRefresh) {
      print('✅ Suppliers đã được load trước đó');
      return;
    }
    
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _suppliers = await _supplierService.getSuppliers();
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
      _suppliers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy tên nhà cung cấp theo ID
  String getSupplierName(String supplierId) {
    if (supplierId.isEmpty) return 'Chưa cập nhật';
    
    try {
      final supplier = _suppliers.firstWhere(
        (s) => s.supplierId == supplierId,
      );
      return supplier.supplierName;
    } catch (e) {
      return 'Trang trại GreenFruit';
    }
  }

  // Lấy nhà cung cấp theo ID
  Supplier? getSupplierById(String supplierId) {
    try {
      return _suppliers.firstWhere((s) => s.supplierId == supplierId);
    } catch (e) {
      return null;
    }
  }

  // Đảm bảo suppliers đã được load
  Future<void> ensureSuppliersLoaded() async {
    if (_hasLoaded) {
      print('✅ Suppliers đã được load trước đó');
      return;
    }
    
    if (_isLoading) {
      print('⏳ Suppliers đang được load, chờ...');
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    await fetchSuppliers();
  }

  // Reset state
  void reset() {
    _suppliers = [];
    _isLoading = false;
    _hasLoaded = false;
    _error = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
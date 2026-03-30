import 'dart:io';
import 'package:flutter/foundation.dart';
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
  bool get hasLoaded => _suppliers.isNotEmpty;

  Future<void> fetchSuppliers() async {
    if (_isLoading) return;
    
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
  
  Future<SupplierModel?> getSupplierById(String supplierId) async {
    try {
      return await _supplierService.getSupplierById(supplierId);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
  
  Future<bool> createSupplier({
    required String supplierName,
    String? address,
    String? phone,
    String? email,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newSupplier = await _supplierService.createSupplier(
        supplierName: supplierName,
        address: address,
        phone: phone,
        email: email,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );
      
      if (newSupplier != null) {
        await fetchSuppliers();
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
  
  Future<bool> updateSupplier({
    required String supplierId,
    required String supplierName,
    String? address,
    String? phone,
    String? email,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedSupplier = await _supplierService.updateSupplier(
        supplierId: supplierId,
        supplierName: supplierName,
        address: address,
        phone: phone,
        email: email,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );
      
      if (updatedSupplier != null) {
        await fetchSuppliers();
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
  
  Future<bool> deleteSupplier(String supplierId) async {
    _isLoading = true;
    _error = null;
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
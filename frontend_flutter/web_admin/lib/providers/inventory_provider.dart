// lib/providers/inventory_provider.dart
import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../services/inventory_service.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _service = InventoryService();
  
  List<Inventory> _inventories = [];
  List<Inventory> _expiringInventories = [];
  List<Inventory> _expiredInventories = [];
  bool _isLoading = false;
  String? _error;

  List<Inventory> get inventories => _inventories;
  List<Inventory> get expiringInventories => _expiringInventories;
  List<Inventory> get expiredInventories => _expiredInventories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== FETCH DATA ====================

  // Tải danh sách tất cả lô hàng
  Future<void> fetchInventories() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _inventories = await _service.getInventories();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print("Lỗi khi tải danh sách lô hàng: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tải lô hàng sắp hết hạn
  Future<void> fetchExpiringInventories({int days = 7}) async {
    try {
      _expiringInventories = await _service.getExpiringInventories(days: days);
      notifyListeners();
    } catch (e) {
      print("Lỗi khi tải lô hàng sắp hết hạn: $e");
    }
  }

  // Tải lô hàng đã hết hạn
  Future<void> fetchExpiredInventories() async {
    try {
      _expiredInventories = await _service.getExpiredInventories();
      notifyListeners();
    } catch (e) {
      print("Lỗi khi tải lô hàng hết hạn: $e");
    }
  }

  // ==================== VALIDATION ====================

  // Kiểm tra mã lô hàng đã tồn tại chưa (case-insensitive)
  // excludeId: dùng để bỏ qua chính lô hàng đang sửa khi kiểm tra
  bool isBatchCodeExists(String batchCode, {String? excludeId}) {
    return _inventories.any((inventory) => 
      inventory.batchCode.toUpperCase() == batchCode.toUpperCase() && 
      inventory.inventoryId != excludeId
    );
  }

  // ==================== CRUD OPERATIONS ====================

  // Tạo lô hàng mới (Nhập hàng)
  Future<bool> createInventory({
    required String productId,
    required String batchCode,
    required int quantity,
    DateTime? manufactureDate,
    required DateTime expiryDate,
    double? importPrice,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final newInventory = await _service.createInventory(
        productId: productId,
        batchCode: batchCode.toUpperCase(),
        quantity: quantity,
        manufactureDate: manufactureDate,
        expiryDate: expiryDate,
        importPrice: importPrice,
      );
      
      if (newInventory != null) {
        _inventories.insert(0, newInventory); // Thêm vào đầu danh sách
        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print("Lỗi tại Provider khi tạo lô hàng: $e");
      rethrow; // Ném lỗi để UI (SnackBar) có thể bắt được và hiển thị
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật lô hàng
  Future<bool> updateInventory({
    required String inventoryId,
    int? quantity,
    DateTime? manufactureDate,
    DateTime? expiryDate,
    double? importPrice,
    String? status,
  }) async {
    try {
      final updatedInventory = await _service.updateInventory(
        inventoryId: inventoryId,
        quantity: quantity,
        manufactureDate: manufactureDate,
        expiryDate: expiryDate,
        importPrice: importPrice,
        status: status,
      );
      
      if (updatedInventory != null) {
        final index = _inventories.indexWhere((inv) => inv.inventoryId == inventoryId);
        if (index != -1) {
          _inventories[index] = updatedInventory;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print("Lỗi khi cập nhật lô hàng: $e");
      rethrow;
    }
  }

  // Xóa lô hàng
  Future<bool> deleteInventory(String inventoryId) async {
    try {
      final success = await _service.deleteInventory(inventoryId);
      if (success) {
        _inventories.removeWhere((inv) => inv.inventoryId == inventoryId);
        _expiringInventories.removeWhere((inv) => inv.inventoryId == inventoryId);
        _expiredInventories.removeWhere((inv) => inv.inventoryId == inventoryId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      print("Lỗi khi xóa lô hàng: $e");
      rethrow;
    }
  }

  // ==================== UTILITIES ====================

  // Tự động cập nhật trạng thái hết hạn
  Future<int> autoUpdateExpired() async {
    try {
      final count = await _service.autoUpdateExpired();
      if (count > 0) {
        await fetchInventories();
        await fetchExpiredInventories();
        await fetchExpiringInventories();
      }
      return count;
    } catch (e) {
      print("Lỗi khi tự động cập nhật hết hạn: $e");
      return 0;
    }
  }

  // Lấy tổng tồn kho của sản phẩm
  Future<int> getTotalStock(String productId) async {
    try {
      return await _service.getTotalStock(productId);
    } catch (e) {
      print("Lỗi khi lấy tổng tồn kho: $e");
      return 0;
    }
  }

  // Clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh toàn bộ dữ liệu
  Future<void> refreshAllData() async {
    await fetchInventories();
    await fetchExpiringInventories();
    await fetchExpiredInventories();
  }
}
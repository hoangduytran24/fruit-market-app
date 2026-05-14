// lib/services/inventory_service.dart
import 'dart:convert';
import '../models/inventory.dart';
import 'api_service.dart';

class InventoryService {
  
  // Lấy tất cả lô hàng
  Future<List<Inventory>> getInventories() async {
    try {
      final response = await ApiService.get('Inventory');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Inventory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getInventories: $e');
      return [];
    }
  }

  // Lấy lô hàng theo sản phẩm
  Future<List<Inventory>> getInventoriesByProduct(String productId) async {
    try {
      final response = await ApiService.get('Inventory/product/$productId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Inventory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getInventoriesByProduct: $e');
      return [];
    }
  }

  // Lấy chi tiết 1 lô hàng
  Future<Inventory?> getInventoryById(String inventoryId) async {
    try {
      final response = await ApiService.get('Inventory/$inventoryId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Inventory.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error in getInventoryById: $e');
      return null;
    }
  }

  // Lấy lô hàng sắp hết hạn
  Future<List<Inventory>> getExpiringInventories({int days = 7}) async {
    try {
      final response = await ApiService.get('Inventory/expiring?days=$days');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Inventory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getExpiringInventories: $e');
      return [];
    }
  }

  // Lấy lô hàng đã hết hạn
  Future<List<Inventory>> getExpiredInventories() async {
    try {
      final response = await ApiService.get('Inventory/expired');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Inventory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getExpiredInventories: $e');
      return [];
    }
  }

  // Lấy tổng tồn kho của sản phẩm
  Future<int> getTotalStock(String productId) async {
    try {
      final response = await ApiService.get('Inventory/stock/$productId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['totalStock'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error in getTotalStock: $e');
      return 0;
    }
  }

  // Nhập hàng mới
  Future<Inventory?> createInventory({
    required String productId,
    required String batchCode,
    required int quantity,
    DateTime? manufactureDate,
    required DateTime expiryDate,
    double? importPrice,
  }) async {
    try {
      final body = {
        'productId': productId,
        'batchCode': batchCode,
        'quantity': quantity,
        if (manufactureDate != null) 
          'manufactureDate': manufactureDate.toIso8601String().split('T').first,
        'expiryDate': expiryDate.toIso8601String().split('T').first,
        if (importPrice != null) 'importPrice': importPrice,
      };
      
      final response = await ApiService.post('Inventory', body: body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Inventory.fromJson(data);
      }
      print('Create inventory failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Error in createInventory: $e');
      return null;
    }
  }

  // Cập nhật lô hàng
  Future<Inventory?> updateInventory({
    required String inventoryId,
    int? quantity,
    DateTime? manufactureDate,
    DateTime? expiryDate,
    double? importPrice,
    String? status,
  }) async {
    try {
      final body = {
        if (quantity != null) 'quantity': quantity,
        if (manufactureDate != null) 
          'manufactureDate': manufactureDate.toIso8601String().split('T').first,
        if (expiryDate != null) 
          'expiryDate': expiryDate.toIso8601String().split('T').first,
        if (importPrice != null) 'importPrice': importPrice,
        if (status != null) 'status': status,
      };
      
      final response = await ApiService.put('Inventory/$inventoryId', body: body);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Inventory.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error in updateInventory: $e');
      return null;
    }
  }

  // Xóa lô hàng
  Future<bool> deleteInventory(String inventoryId) async {
    try {
      final response = await ApiService.delete('Inventory/$inventoryId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error in deleteInventory: $e');
      return false;
    }
  }

  // Tự động cập nhật trạng thái hết hạn
  Future<int> autoUpdateExpired() async {
    try {
      final response = await ApiService.post('Inventory/auto-update-expired');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error in autoUpdateExpired: $e');
      return 0;
    }
  }
}
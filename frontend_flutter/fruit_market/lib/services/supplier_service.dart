import 'dart:convert';
import 'api_service.dart';
import '../models/Supplier.dart';

class SupplierService {
  
  // Lấy danh sách nhà cung cấp
  Future<List<Supplier>> getSuppliers() async {
    try {
      print('📋 Fetching suppliers');
      
      final response = await ApiService.getPublic('Suppliers');
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final suppliers = data.map((item) => Supplier.fromJson(item)).toList();
        print('✅ Loaded ${suppliers.length} suppliers');
        return suppliers;
      } else {
        print('❌ Failed to load suppliers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading suppliers: $e');
      return [];
    }
  }

  // Lấy nhà cung cấp theo ID
  Future<Supplier?> getSupplierById(String supplierId) async {
    try {
      print('📋 Fetching supplier: $supplierId');
      
      final response = await ApiService.getPublic('Suppliers/$supplierId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Supplier.fromJson(data);
      } else {
        print('❌ Failed to load supplier: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error loading supplier: $e');
      return null;
    }
  }
}
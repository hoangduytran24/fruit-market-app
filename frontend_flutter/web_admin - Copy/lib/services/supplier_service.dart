import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/supplier.dart';
import 'api_service.dart';

class SupplierService {
  // --- LẤY DANH SÁCH ---
  Future<List<SupplierModel>> getSuppliers() async {
    try {
      final response = await ApiService.get('Suppliers');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SupplierModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getSuppliers: $e');
      return [];
    }
  }

  // --- LẤY CHI TIẾT ---
  Future<SupplierModel?> getSupplierById(String supplierId) async {
    try {
      final response = await ApiService.get('Suppliers/$supplierId');
      if (response.statusCode == 200) {
        return SupplierModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in getSupplierById: $e');
      return null;
    }
  }

  // --- TẠO MỚI (Khớp Swagger application/json) ---
  Future<SupplierModel?> createSupplier({
    required String supplierName,
    String? address,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}Suppliers'),
        headers: {
          ...(await ApiService.authHeaders),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "supplierName": supplierName,
          "phone": phone ?? "",
          "email": email ?? "",
          "address": address ?? "",
        }),
      );

      print('Create Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SupplierModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in createSupplier: $e');
      return null;
    }
  }

  // --- CẬP NHẬT (Khớp Swagger application/json) ---
  Future<SupplierModel?> updateSupplier({
    required String supplierId,
    required String supplierName,
    String? address,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}Suppliers/$supplierId'),
        headers: {
          ...(await ApiService.authHeaders),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "supplierName": supplierName,
          "phone": phone ?? "",
          "email": email ?? "",
          "address": address ?? "",
          "status": "active" // Backend yêu cầu status khi PUT
        }),
      );

      print('Update Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return SupplierModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in updateSupplier: $e');
      return null;
    }
  }

  // --- XÓA ---
  Future<bool> deleteSupplier(String supplierId) async {
    try {
      final response = await ApiService.delete('Suppliers/$supplierId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error in deleteSupplier: $e');
      return false;
    }
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/supplier.dart';
import 'api_service.dart';

class SupplierService {
  
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
  
  Future<SupplierModel?> getSupplierById(String supplierId) async {
    try {
      final response = await ApiService.get('Suppliers/$supplierId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SupplierModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error in getSupplierById: $e');
      return null;
    }
  }
  
  Future<SupplierModel?> createSupplier({
    required String supplierName,
    String? address,
    String? phone,
    String? email,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      print('=== CREATE SUPPLIER ===');
      print('SupplierName: $supplierName');
      print('Address: $address');
      print('Phone: $phone');
      print('Email: $email');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}Suppliers'),
      );
      
      final headers = await ApiService.authHeaders;
      request.headers.addAll(headers);
      
      request.fields['supplierName'] = supplierName;
      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address;
      }
      if (phone != null && phone.isNotEmpty) {
        request.fields['phone'] = phone;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }
      
      // Xử lý ảnh
      if (kIsWeb && imageBytes != null && imageBytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: 'supplier_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (!kIsWeb && imageFile != null && await imageFile.exists()) {
        request.files.add(await http.MultipartFile.fromPath(
          'imageFile',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return SupplierModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in createSupplier: $e');
      return null;
    }
  }
  
  Future<SupplierModel?> updateSupplier({
    required String supplierId,
    required String supplierName,
    String? address,
    String? phone,
    String? email,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      print('=== UPDATE SUPPLIER ===');
      print('SupplierId: $supplierId');
      print('SupplierName: $supplierName');
      
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiService.baseUrl}Suppliers/$supplierId'),
      );
      
      final headers = await ApiService.authHeaders;
      request.headers.addAll(headers);
      
      request.fields['supplierName'] = supplierName;
      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address;
      }
      if (phone != null && phone.isNotEmpty) {
        request.fields['phone'] = phone;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }
      
      // Xử lý ảnh
      if (kIsWeb && imageBytes != null && imageBytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: 'supplier_update.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (!kIsWeb && imageFile != null && await imageFile.exists()) {
        request.files.add(await http.MultipartFile.fromPath(
          'imageFile',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return SupplierModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in updateSupplier: $e');
      return null;
    }
  }
  
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
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/category.dart';
import 'api_service.dart';

class CategoryService {
  
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await ApiService.get('Categories');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getCategories: $e');
      return [];
    }
  }
  
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final response = await ApiService.get('Categories/$categoryId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CategoryModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error in getCategoryById: $e');
      return null;
    }
  }
  
  Future<CategoryModel?> createCategory({
    required String categoryName,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      print('=== CREATE CATEGORY ===');
      print('CategoryName: $categoryName');
      print('Description: $description');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}Categories'),
      );
      
      final headers = await ApiService.authHeaders;
      request.headers.addAll(headers);
      
      request.fields['categoryName'] = categoryName;
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      
      // Xử lý ảnh
      if (kIsWeb && imageBytes != null && imageBytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: 'category_image.jpg',
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
        return CategoryModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in createCategory: $e');
      return null;
    }
  }
  
  Future<CategoryModel?> updateCategory({
    required String categoryId,
    required String categoryName,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      print('=== UPDATE CATEGORY ===');
      print('CategoryId: $categoryId');
      print('CategoryName: $categoryName');
      
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiService.baseUrl}Categories/$categoryId'),
      );
      
      final headers = await ApiService.authHeaders;
      request.headers.addAll(headers);
      
      request.fields['categoryName'] = categoryName;
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      
      // Xử lý ảnh
      if (kIsWeb && imageBytes != null && imageBytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: 'category_update.jpg',
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
        return CategoryModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in updateCategory: $e');
      return null;
    }
  }
  
  Future<bool> deleteCategory(String categoryId) async {
    try {
      final response = await ApiService.delete('Categories/$categoryId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error in deleteCategory: $e');
      return false;
    }
  }
}
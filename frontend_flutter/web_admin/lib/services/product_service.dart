import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  
  Future<PaginatedProductResponse> getProductsWithPagination({
    int page = 1,
    int pageSize = 10,
    String? keyword,
    String? categoryId,
  }) async {
    try {
      final query = <String, String>{
        'Page': page.toString(),
        'PageSize': pageSize.toString(),
        if (keyword != null && keyword.isNotEmpty) 'Keyword': keyword,
        if (categoryId != null && categoryId.isNotEmpty) 'CategoryId': categoryId,
      };
      
      final uri = Uri.parse('${ApiService.baseUrl}Products')
          .replace(queryParameters: query);
      
      final response = await ApiService.get('Products?${uri.query}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaginatedProductResponse.fromJson(data);
      }
      return PaginatedProductResponse(
        items: [],
        totalCount: 0,
        page: page,
        pageSize: pageSize,
        totalPages: 1,
      );
    } catch (e) {
      print('Error in getProductsWithPagination: $e');
      rethrow;
    }
  }
  
  Future<Product?> getProductById(String productId) async {
    try {
      final response = await ApiService.get('Products/$productId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error in getProductById: $e');
      return null;
    }
  }
  
  Future<Product?> createProduct({
    required String productName,
    required String categoryId,
    required String supplierId,
    required String unit,
    required double price,
    required int stockQuantity,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      print('=== CREATE PRODUCT ===');
      print('ProductName: $productName');
      print('CategoryId: $categoryId');
      print('SupplierId: $supplierId');
      print('IsWeb: $kIsWeb');
      print('Has imageFile: ${imageFile != null}');
      print('Has imageBytes: ${imageBytes != null}');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}Products'),
      );
      
      final headers = await ApiService.authHeaders;
      request.headers.addAll(headers);
      
      request.fields['productName'] = productName;
      request.fields['categoryId'] = categoryId;
      request.fields['supplierId'] = supplierId;
      request.fields['unit'] = unit;
      request.fields['price'] = price.toString();
      request.fields['stockQuantity'] = stockQuantity.toString();
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      
      // XỬ LÝ FILE ẢNH - Đảm bảo gửi đúng tên field "imageFile"
      if (kIsWeb && imageBytes != null && imageBytes.isNotEmpty) {
        print('Adding image bytes for Web, size: ${imageBytes.length}');
        request.files.add(http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: 'product_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (!kIsWeb && imageFile != null && await imageFile.exists()) {
        print('Adding image file for Mobile: ${imageFile.path}');
        request.files.add(await http.MultipartFile.fromPath(
          'imageFile',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      } else {
        // Nếu không có ảnh, vẫn gửi một file rỗng (backend yêu cầu required)
        print('No image provided, sending empty file');
        final emptyBytes = Uint8List.fromList([]);
        request.files.add(http.MultipartFile.fromBytes(
          'imageFile',
          emptyBytes,
          filename: 'empty.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      
      print('Sending request to: ${request.url}');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Product.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in createProduct: $e');
      return null;
    }
  }
  
  Future<Product?> updateProduct({
    required String productId,
    required String productName,
    required String categoryId,
    required String supplierId,
    required String unit,
    required double price,
    required int stockQuantity,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
    required bool isActive,
  }) async {
    try {
      print('=== UPDATE PRODUCT ===');
      print('ProductId: $productId');
      print('ProductName: $productName');
      
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiService.baseUrl}Products/$productId'),
      );
      
      final headers = await ApiService.authHeaders;
      request.headers.addAll(headers);
      
      request.fields['productName'] = productName;
      request.fields['categoryId'] = categoryId;
      request.fields['supplierId'] = supplierId;
      request.fields['unit'] = unit;
      request.fields['price'] = price.toString();
      request.fields['stockQuantity'] = stockQuantity.toString();
      request.fields['isActive'] = isActive.toString();
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      
      if (kIsWeb && imageBytes != null && imageBytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: 'product_update.jpg',
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
        return Product.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in updateProduct: $e');
      return null;
    }
  }
  
  Future<bool> deleteProduct(String productId) async {
    try {
      final response = await ApiService.delete('Products/$productId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error in deleteProduct: $e');
      return false;
    }
  }
}

class PaginatedProductResponse {
  final List<Product> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  
  PaginatedProductResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });
  
  factory PaginatedProductResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedProductResponse(
      items: (json['items'] as List?)
          ?.map((e) => Product.fromJson(e))
          .toList() ?? [],
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
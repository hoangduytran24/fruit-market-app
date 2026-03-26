import 'dart:convert';
import '../services/api_service.dart';

class CategoryService {
  // Lấy tất cả danh mục - GET /api/Categories
  static Future<Map<String, dynamic>> getAllCategories() async {
    try {
      print('📋 Fetching all categories');
      // Dùng getPublic vì categories không cần token
      final response = await ApiService.getPublic('Categories');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Loaded ${data.length} categories');
        return {
          'success': true,
          'data': data,
        };
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': 'Không thể tải danh mục (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error in getAllCategories: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Lấy danh mục theo ID - GET /api/Categories/{id}
  static Future<Map<String, dynamic>> getCategoryById(String categoryId) async {
    try {
      print('📋 Fetching category: $categoryId');
      final response = await ApiService.getPublic('Categories/$categoryId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Loaded category: ${data['categoryName']}');
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Không tìm thấy danh mục',
        };
      } else {
        return {
          'success': false,
          'message': 'Không thể tải danh mục (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error in getCategoryById: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Tạo danh mục mới - POST /api/Categories (cần token - admin)
  static Future<Map<String, dynamic>> createCategory({
    required String categoryName,
    String? description,
    dynamic imageFile, // Sẽ xử lý sau nếu cần upload file
  }) async {
    try {
      print('➕ Creating category: $categoryName');
      
      final response = await ApiService.post(
        'Categories',
        body: {
          'categoryName': categoryName,
          'description': description,
          // 'imageFile': imageFile, // Cần xử lý multipart nếu upload file
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Created category: ${data['categoryId']}');
        return {
          'success': true,
          'data': data,
        };
      } else {
        String message = 'Không thể tạo danh mục';
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? message;
        } catch (_) {}
        
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      print('❌ Error in createCategory: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Cập nhật danh mục - PUT /api/Categories/{id} (cần token - admin)
  static Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    required String categoryName,
    String? description,
    dynamic imageFile,
  }) async {
    try {
      print('✏️ Updating category: $categoryId');
      
      final response = await ApiService.put(
        'Categories/$categoryId',
        body: {
          'categoryName': categoryName,
          'description': description,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Updated category: $categoryId');
        return {
          'success': true,
          'data': data,
        };
      } else {
        String message = 'Không thể cập nhật danh mục';
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? message;
        } catch (_) {}
        
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      print('❌ Error in updateCategory: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Xóa danh mục - DELETE /api/Categories/{id} (cần token - admin)
  static Future<Map<String, dynamic>> deleteCategory(String categoryId) async {
    try {
      print('🗑️ Deleting category: $categoryId');
      
      final response = await ApiService.delete('Categories/$categoryId');
      
      if (response.statusCode == 200) {
        print('✅ Deleted category: $categoryId');
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        String message = 'Không thể xóa danh mục';
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? message;
        } catch (_) {}
        
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      print('❌ Error in deleteCategory: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }
}
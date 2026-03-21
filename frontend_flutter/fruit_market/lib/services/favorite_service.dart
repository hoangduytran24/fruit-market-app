import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/favorite.dart';

class FavoriteService {
  // Lấy danh sách yêu thích - GET /api/favorites
  static Future<Map<String, dynamic>> getUserFavorites() async {
    try {
      print('📋 Fetching favorites');
      final response = await ApiService.get('favorites');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Loaded ${data['totalCount'] ?? 0} favorites');
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Phiên đăng nhập hết hạn',
        };
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': 'Không thể tải danh sách yêu thích (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error in getUserFavorites: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Thêm vào yêu thích - POST /api/favorites
  static Future<Map<String, dynamic>> addFavorite(String productId) async {
    try {
      print('➕ Adding favorite - Product: $productId');
      
      // DTO: CreateFavoriteDto { "productId": "..." }
      final response = await ApiService.post(
        'favorites',
        body: {'productId': productId},
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Added favorite successfully');
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Phiên đăng nhập hết hạn',
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': 'Sản phẩm đã có trong danh sách yêu thích',
        };
      } else {
        String message = 'Không thể thêm vào yêu thích';
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
      print('❌ Error in addFavorite: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Xóa khỏi yêu thích - DELETE /api/favorites/{productId}
  static Future<Map<String, dynamic>> removeFavorite(String productId) async {
    try {
      print('➖ Removing favorite - Product: $productId');
      
      final response = await ApiService.delete('favorites/$productId');
      
      if (response.statusCode == 200) {
        print('✅ Removed favorite successfully');
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Phiên đăng nhập hết hạn',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Sản phẩm không có trong danh sách yêu thích',
        };
      } else {
        String message = 'Không thể xóa khỏi yêu thích';
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
      print('❌ Error in removeFavorite: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }
}
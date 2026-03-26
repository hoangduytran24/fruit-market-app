import 'dart:convert';
import 'api_service.dart';

class ReviewService {
  
  // Lấy danh sách đánh giá của sản phẩm
  Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    try {
      print('📋 Fetching reviews for product: $productId');
      
      final response = await ApiService.get('Reviews/product/$productId');
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Loaded ${data.length} reviews');
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        print('❌ Failed to load reviews: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading reviews: $e');
      return [];
    }
  }

  // Kiểm tra người dùng đã mua sản phẩm chưa
  Future<bool> checkUserPurchasedProduct(String productId, String userId) async {
    try {
      print('🔍 Checking purchase: product=$productId, user=$userId');
      
      // SỬA: endpoint đúng là /Reviews/check-purchase
      final response = await ApiService.get(
        'Reviews/check-purchase?productId=$productId'
      );
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hasPurchased = data['hasPurchased'] ?? false;
        print('✅ Purchase check result: $hasPurchased');
        return hasPurchased;
      } else {
        print('❌ Purchase check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error checking purchase: $e');
      return false;
    }
  }

  // Tạo đánh giá mới
  Future<Map<String, dynamic>?> createReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    try {
      print('📝 Creating review for product: $productId');
      print('📝 Rating: $rating, Comment: $comment');
      
      final intRating = rating.toInt();
      
      final body = {
        'productId': productId,
        'rating': intRating,
        'comment': comment,
      };
      
      print('📦 Body: $body');
      
      final response = await ApiService.post('Reviews', body: body);
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Review created successfully with ID: ${data['reviewId']}');
        return Map<String, dynamic>.from(data);
      } else {
        print('❌ Failed to create review: ${response.statusCode}');
        print('📥 Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating review: $e');
      return null;
    }
  }

  // Xóa đánh giá
  Future<bool> deleteReview(String reviewId) async {
    try {
      print('🗑️ Deleting review: $reviewId');
      
      final response = await ApiService.delete('Reviews/$reviewId');
      
      if (response.statusCode == 200) {
        print('✅ Review deleted successfully');
        return true;
      } else {
        print('❌ Failed to delete review: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting review: $e');
      return false;
    }
  }
}
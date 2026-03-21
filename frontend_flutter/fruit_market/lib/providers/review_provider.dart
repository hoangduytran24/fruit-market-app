import 'package:flutter/material.dart';
import '../services/review_service.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get reviews => _reviews;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(
      0, 
      (total, review) => total + (review['rating'] as num).toDouble()
    );
    return sum / _reviews.length;
  }

  int get totalReviews => _reviews.length;

  // Lấy đánh giá của sản phẩm
  Future<void> fetchProductReviews(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reviews = await _reviewService.getProductReviews(productId);
      print('✅ Loaded ${_reviews.length} reviews in provider');
    } catch (e) {
      print('❌ Error in fetchProductReviews: $e');
      _error = 'Không thể tải đánh giá';
      _reviews = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kiểm tra người dùng đã mua sản phẩm chưa
  Future<bool> checkUserPurchasedProduct(String productId, String userId) async {
    try {
      return await _reviewService.checkUserPurchasedProduct(productId, userId);
    } catch (e) {
      print('❌ Error in checkUserPurchasedProduct: $e');
      return false;
    }
  }

  // Tạo đánh giá mới
  Future<bool> createReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final newReview = await _reviewService.createReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );

      if (newReview != null) {
        _reviews.insert(0, newReview);
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Không thể tạo đánh giá';
        _isSubmitting = false;
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      print('❌ Error in createReview: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // Xóa đánh giá
  Future<bool> deleteReview(String reviewId) async {
    try {
      final success = await _reviewService.deleteReview(reviewId);
      
      if (success) {
        _reviews.removeWhere((review) => review['reviewId'] == reviewId);
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      print('❌ Error in deleteReview: $e');
      return false;
    }
  }

  // Reset state
  void reset() {
    _reviews = [];
    _error = null;
    _isLoading = false;
    _isSubmitting = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
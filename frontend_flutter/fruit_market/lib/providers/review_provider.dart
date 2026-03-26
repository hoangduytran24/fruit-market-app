import 'package:flutter/material.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  bool _hasLoaded = false; // THÊM
  bool _isFetching = false; // THÊM
  String? _currentProductId; // THÊM: lưu productId hiện tại

  // Getters
  List<Map<String, dynamic>> get reviews => _reviews;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get hasLoaded => _hasLoaded; // THÊM
  bool get isFetching => _isFetching; // THÊM
  bool get hasReviews => _reviews.isNotEmpty; // THÊM

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(
      0, 
      (total, review) => total + (review['rating'] as num).toDouble()
    );
    return sum / _reviews.length;
  }

  int get totalReviews => _reviews.length;

  // Lấy đánh giá của sản phẩm - THÊM: kiểm tra đã load
  Future<void> fetchProductReviews(String productId, {bool forceRefresh = false}) async {
    // Nếu đang fetch thì bỏ qua
    if (_isFetching) {
      print('⏳ Đang fetch reviews, bỏ qua request');
      return;
    }
    
    // Nếu đã load cùng productId và không force refresh thì bỏ qua
    if (_hasLoaded && _currentProductId == productId && !forceRefresh) {
      print('✅ Đã load reviews cho product $productId trước đó, bỏ qua fetch');
      return;
    }
    
    // Nếu đang loading thì bỏ qua
    if (_isLoading) {
      print('⏳ Đang loading reviews, bỏ qua request');
      return;
    }

    _isFetching = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reviews = await _reviewService.getProductReviews(productId);
      _currentProductId = productId; // THÊM: lưu productId
      _hasLoaded = true; // THÊM
      print('✅ Loaded ${_reviews.length} reviews in provider');
    } catch (e) {
      print('❌ Error in fetchProductReviews: $e');
      _error = 'Không thể tải đánh giá';
      _reviews = [];
      _hasLoaded = false;
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  // THÊM: Đảm bảo reviews đã được load
  Future<void> ensureReviewsLoaded(String productId) async {
    if (_hasLoaded && _currentProductId == productId && _reviews.isNotEmpty) {
      print('✅ Reviews đã được load trước đó');
      return;
    }
    
    if (_isFetching || _isLoading) {
      print('⏳ Reviews đang được load, chờ...');
      while (_isFetching || _isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    await fetchProductReviews(productId);
  }

  // THÊM: Load reviews silently (không set loading state)
  Future<void> loadReviewsSilently(String productId) async {
    if (_hasLoaded && _currentProductId == productId) return;
    
    try {
      _reviews = await _reviewService.getProductReviews(productId);
      _currentProductId = productId;
      _hasLoaded = true;
      notifyListeners();
    } catch (e) {
      print('❌ Load reviews silently error: $e');
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
        _hasLoaded = true; // THÊM
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

  // THÊM: Làm mới dữ liệu (force refresh)
  Future<void> refreshReviews(String productId) async {
    await fetchProductReviews(productId, forceRefresh: true);
  }

  // THÊM: Xóa cache reviews (khi chuyển sản phẩm)
  void clearReviewsCache() {
    _hasLoaded = false;
    _currentProductId = null;
    _reviews = [];
    notifyListeners();
  }

  // Reset state
  void reset() {
    _reviews = [];
    _error = null;
    _isLoading = false;
    _isSubmitting = false;
    _hasLoaded = false;
    _isFetching = false;
    _currentProductId = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // THÊM: Lấy review theo index
  Map<String, dynamic>? getReviewAtIndex(int index) {
    if (index >= 0 && index < _reviews.length) {
      return _reviews[index];
    }
    return null;
  }

  // THÊM: Lấy số lượng review theo rating
  Map<int, int> getRatingDistribution() {
    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var review in _reviews) {
      final rating = (review['rating'] as num).toInt();
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }
    return distribution;
  }
}
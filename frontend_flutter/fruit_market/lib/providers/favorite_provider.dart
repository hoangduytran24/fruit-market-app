import 'package:flutter/material.dart';
import '../models/favorite.dart';
import '../services/favorite_service.dart';

class FavoriteProvider extends ChangeNotifier {
  List<Favorite> _favorites = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isFetching = false;
  String? _error;
  final Map<String, bool> _favoriteStatus = {};

  // Getters
  List<Favorite> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get isFetching => _isFetching; // THÊM
  String? get error => _error;
  int get totalCount => _favorites.length;
  bool get hasFavorites => _favorites.isNotEmpty; // THÊM

  bool isFavorite(String productId) {
    return _favoriteStatus[productId] ?? false;
  }

  Future<bool> fetchFavorites({bool forceRefresh = false}) async {
    // Nếu đang fetch thì bỏ qua
    if (_isFetching) {
      print('⏳ Đang fetch favorites, bỏ qua request');
      return false;
    }
    
    // Nếu đã load và không force refresh thì bỏ qua
    if (_hasLoaded && !forceRefresh) {
      print('✅ Đã load favorites trước đó, bỏ qua fetch');
      return true;
    }

    _isFetching = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📋 Fetching favorites');
      final result = await FavoriteService.getUserFavorites();
      
      if (result['success'] == true) {
        final List<dynamic> items = result['data']?['items'] ?? [];
        _favorites = items.map((json) => Favorite.fromJson(json)).toList();
        
        _updateFavoriteCache();
        
        _isLoading = false;
        _hasLoaded = true;
        _isFetching = false;
        notifyListeners();
        return true;
      } else {
        _favorites = [];
        _updateFavoriteCache();
        _hasLoaded = true;
        _error = result['message'];
        _isLoading = false;
        _isFetching = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
      return false;
    }
  }

  // THÊM: Đảm bảo favorites đã được load
  Future<void> ensureFavoritesLoaded() async {
    if (_hasLoaded) {
      print('✅ Favorites đã được load trước đó');
      return;
    }
    
    if (_isFetching || _isLoading) {
      print('⏳ Favorites đang được load, chờ...');
      while (_isFetching || _isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    print('📢 ensureFavoritesLoaded: gọi fetchFavorites');
    await fetchFavorites();
  }

  // THÊM: Load favorites silently (không set loading state)
  Future<void> loadFavoritesSilently() async {
    if (_hasLoaded) return;
    
    try {
      final result = await FavoriteService.getUserFavorites();
      if (result['success'] == true) {
        final List<dynamic> items = result['data']?['items'] ?? [];
        _favorites = items.map((json) => Favorite.fromJson(json)).toList();
        _updateFavoriteCache();
        _hasLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Load favorites silently error: $e');
    }
  }

  Future<bool> addFavorite(String productId) async {
    _error = null;
    
    // Optimistic update
    _favoriteStatus[productId] = true;
    notifyListeners();

    try {
      final result = await FavoriteService.addFavorite(productId);
      
      if (result['success'] == true) {
        // THÊM: refresh favorites sau khi thêm
        await fetchFavorites(forceRefresh: true);
        return true;
      } else {
        // Rollback nếu thất bại
        _favoriteStatus[productId] = false;
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Rollback nếu có lỗi
      _favoriteStatus[productId] = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFavorite(String productId) async {
    _error = null;
    
    // Optimistic update
    _favoriteStatus[productId] = false;
    _favorites.removeWhere((f) => f.productId == productId);
    notifyListeners();

    try {
      final result = await FavoriteService.removeFavorite(productId);
      
      if (result['success'] == true) {
        // THÊM: refresh favorites sau khi xóa
        await fetchFavorites(forceRefresh: true);
        return true;
      } else {
        // Rollback nếu thất bại
        await fetchFavorites(forceRefresh: true);
        _error = result['message'];
        return false;
      }
    } catch (e) {
      // Rollback nếu có lỗi
      await fetchFavorites(forceRefresh: true);
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> toggleFavorite(String productId) async {
    if (isFavorite(productId)) {
      return await removeFavorite(productId);
    } else {
      return await addFavorite(productId);
    }
  }

  void _updateFavoriteCache() {
    _favoriteStatus.clear();
    for (var fav in _favorites) {
      _favoriteStatus[fav.productId] = true;
    }
  }

  // THÊM: Clear favorites (reset state)
  void clearFavorites() {
    _favorites.clear();
    _favoriteStatus.clear();
    _error = null;
    _hasLoaded = false;
    _isFetching = false;
    _isLoading = false;
    notifyListeners();
  }

  // THÊM: Reset state
  void reset() {
    _favorites = [];
    _isLoading = false;
    _hasLoaded = false;
    _isFetching = false;
    _error = null;
    _favoriteStatus.clear();
    notifyListeners();
  }

  // THÊM: Làm mới dữ liệu (force refresh)
  Future<bool> refreshFavorites() async {
    return await fetchFavorites(forceRefresh: true);
  }

  // THÊM: Lấy danh sách productIds yêu thích
  List<String> getFavoriteProductIds() {
    return _favorites.map((f) => f.productId).toList();
  }

  // THÊM: Kiểm tra có sản phẩm nào trong danh sách không
  bool containsProduct(String productId) {
    return _favoriteStatus[productId] ?? false;
  }

  // THÊM: Xóa lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
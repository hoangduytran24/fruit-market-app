import 'package:flutter/material.dart';
import '../models/favorite.dart';
import '../services/favorite_service.dart';

class FavoriteProvider with ChangeNotifier {
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
  String? get error => _error;
  int get totalCount => _favorites.length;

  bool isFavorite(String productId) {
    return _favoriteStatus[productId] ?? false;
  }

  Future<bool> fetchFavorites({bool forceRefresh = false}) async {
    if (_isFetching) {
      print('⏳ Đang fetch favorites, bỏ qua request');
      return false;
    }
    
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

  Future<bool> addFavorite(String productId) async {
    _error = null;
    
    _favoriteStatus[productId] = true;
    notifyListeners();

    try {
      final result = await FavoriteService.addFavorite(productId);
      
      if (result['success'] == true) {
        await fetchFavorites(forceRefresh: true);
        return true;
      } else {
        _favoriteStatus[productId] = false;
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _favoriteStatus[productId] = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFavorite(String productId) async {
    _error = null;
    
    _favoriteStatus[productId] = false;
    _favorites.removeWhere((f) => f.productId == productId);
    notifyListeners();

    try {
      final result = await FavoriteService.removeFavorite(productId);
      
      if (result['success'] == true) {
        return true;
      } else {
        await fetchFavorites(forceRefresh: true);
        _error = result['message'];
        return false;
      }
    } catch (e) {
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

  void clearFavorites() {
    _favorites.clear();
    _favoriteStatus.clear();
    _error = null;
    _hasLoaded = false;
    _isFetching = false;
    notifyListeners();
  }

  Future<void> ensureFavoritesLoaded() async {
    if (!_hasLoaded && !_isLoading && !_isFetching) {
      print('📢 ensureFavoritesLoaded: gọi fetchFavorites');
      await fetchFavorites();
    } else {
      print('📢 ensureFavoritesLoaded: bỏ qua - hasLoaded: $_hasLoaded, isLoading: $_isLoading, isFetching: $_isFetching');
    }
  }
}
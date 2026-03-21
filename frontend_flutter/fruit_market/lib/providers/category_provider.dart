import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isFetching = false; // THÊM BIẾN NÀY
  String? _error;
  Category? _selectedCategory;

  // Getters
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  Category? get selectedCategory => _selectedCategory;
  int get totalCount => _categories.length;

  // Lấy tất cả danh mục
  Future<bool> fetchCategories({bool forceRefresh = false}) async {
    // Nếu đang fetch thì không gọi lại
    if (_isFetching) {
      print('⏳ Đang fetch categories, bỏ qua request');
      return false;
    }
    
    if (_hasLoaded && !forceRefresh) {
      print('✅ Đã load categories trước đó, bỏ qua fetch');
      return true;
    }

    _isFetching = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📋 Fetching categories');
      final result = await CategoryService.getAllCategories();
      
      if (result['success'] == true) {
        final List<dynamic> items = result['data'] ?? [];
        _categories = items.map((json) => Category.fromJson(json)).toList();
        
        _isLoading = false;
        _hasLoaded = true;
        _isFetching = false;
        notifyListeners();
        return true;
      } else {
        _categories = [];
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

  // Lấy danh mục theo ID
  Future<Category?> getCategoryById(String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await CategoryService.getCategoryById(categoryId);
      
      if (result['success'] == true) {
        final category = Category.fromJson(result['data']);
        _selectedCategory = category;
        _isLoading = false;
        notifyListeners();
        return category;
      } else {
        _error = result['message'];
        _selectedCategory = null;
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Lấy danh mục theo tên (tìm kiếm)
  List<Category> searchCategories(String query) {
    if (query.isEmpty) return _categories;
    
    return _categories.where((category) =>
      category.categoryName.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Lấy danh mục có nhiều sản phẩm nhất
  List<Category> getPopularCategories({int limit = 5}) {
    final sorted = List<Category>.from(_categories)
      ..sort((a, b) => b.productCount.compareTo(a.productCount));
    
    return sorted.take(limit).toList();
  }

  // Đảm bảo categories đã được load
  Future<void> ensureCategoriesLoaded() async {
    if (!_hasLoaded && !_isLoading && !_isFetching) {
      await fetchCategories();
    }
  }

  // Reset state
  void reset() {
    _categories = [];
    _error = null;
    _isLoading = false;
    _hasLoaded = false;
    _isFetching = false;
    _selectedCategory = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
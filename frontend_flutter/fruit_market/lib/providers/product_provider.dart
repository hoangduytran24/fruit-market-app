import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _newProducts = [];
  List<Product> _bestSellers = [];
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isFetching = false; // THÊM BIẾN NÀY
  String? _error;
  
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  String? _searchKeyword;
  String? _selectedCategoryId;

  // Getters
  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get newProducts => _newProducts;
  List<Product> get bestSellers => _bestSellers;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _currentPage < _totalPages;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  final ProductService _productService = ProductService();

  // Tải danh sách sản phẩm
  Future<void> loadProducts({bool refresh = false}) async {
    // Chống gọi đồng thời
    if (_isFetching) {
      print('⏳ Đang fetch products, bỏ qua request');
      return;
    }
    
    if (refresh) {
      _currentPage = 1;
      _products = [];
      _totalPages = 1;
    }

    if (_isLoading) return;

    _isFetching = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Đang tải sản phẩm trang $_currentPage...');
      
      final response = await _productService.getProductsWithPagination(
        keyword: _searchKeyword,
        categoryId: _selectedCategoryId,
        page: _currentPage,
        pageSize: 10,
      );

      print('✅ Đã tải ${response.items.length} sản phẩm từ trang $_currentPage');

      _products = response.items;
      _totalCount = response.totalCount;
      _totalPages = response.totalPages;

      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi tải sản phẩm: $e');
      _isLoading = false;
      _isFetching = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Tải thêm sản phẩm
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !hasMore || _isFetching) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      print('🔄 Đang tải thêm sản phẩm trang $nextPage...');
      
      final response = await _productService.getProductsWithPagination(
        keyword: _searchKeyword,
        categoryId: _selectedCategoryId,
        page: nextPage,
        pageSize: 10,
      );

      print('✅ Đã tải thêm ${response.items.length} sản phẩm');

      _products = [..._products, ...response.items];
      _totalCount = response.totalCount;
      _totalPages = response.totalPages;
      _currentPage = nextPage;

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi tải thêm sản phẩm: $e');
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Chuyển đến trang
  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _currentPage || _isFetching) return;
    
    _currentPage = page;
    await loadProducts(refresh: true);
  }

  // Lọc theo danh mục
  Future<void> filterByCategory(String categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    
    _selectedCategoryId = categoryId;
    _searchKeyword = null;
    _currentPage = 1;
    _products = [];
    await loadProducts(refresh: true);
  }

  // Tìm kiếm sản phẩm
  Future<void> searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      await refreshProducts();
      return;
    }

    _searchKeyword = keyword;
    _selectedCategoryId = null;
    _currentPage = 1;
    _products = [];
    await loadProducts(refresh: true);
  }

  // Refresh danh sách
  Future<void> refreshProducts() async {
    _selectedCategoryId = null;
    _searchKeyword = null;
    _currentPage = 1;
    _products = [];
    await loadProducts(refresh: true);
  }

  // Xóa bộ lọc tìm kiếm
  void clearSearch() {
    _searchKeyword = null;
    _selectedCategoryId = null;
    refreshProducts();
  }

  // Reset lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Các phương thức khác giữ nguyên...
  Future<void> loadFeaturedProducts() async {
    try {
      _featuredProducts = await _productService.getFeaturedProducts();
      notifyListeners();
    } catch (e) {
      print('Lỗi tải sản phẩm nổi bật: $e');
    }
  }

  Future<void> loadNewProducts() async {
    try {
      _newProducts = await _productService.getNewProducts();
      notifyListeners();
    } catch (e) {
      print('Lỗi tải sản phẩm mới: $e');
    }
  }

  Future<void> loadBestSellers() async {
    try {
      _bestSellers = await _productService.getBestSellers();
      notifyListeners();
    } catch (e) {
      print('Lỗi tải sản phẩm bán chạy: $e');
    }
  }

  Future<void> loadAllProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadFeaturedProducts(),
        loadNewProducts(),
        loadBestSellers(),
      ]);
      
      await loadProducts(refresh: true);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      return await _productService.getProduct(id);
    } catch (e) {
      print('Lỗi lấy chi tiết sản phẩm: $e');
      return null;
    }
  }
}
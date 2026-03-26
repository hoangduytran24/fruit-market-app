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
  bool _isFetching = false;
  String? _error;
  bool _hasLoaded = false;
  
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
  bool get hasLoaded => _hasLoaded;
  bool get isFetching => _isFetching;
  bool get hasData => _products.isNotEmpty;

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
      _hasLoaded = false;
    }

    // Nếu đã load và không refresh thì bỏ qua
    if (_hasLoaded && !refresh && _products.isNotEmpty) {
      print('✅ Products đã được load trước đó, bỏ qua fetch');
      return;
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

      // SỬA: Xử lý null values từ API response (bỏ currentPage)
      _products = response.items ?? [];
      _totalCount = response.totalCount;
      _totalPages = response.totalPages ?? 1;
      
      print('✅ Đã tải ${_products.length} sản phẩm từ trang $_currentPage');
      print('📊 Tổng số trang: $_totalPages, Tổng số sản phẩm: $_totalCount');

      _hasLoaded = true;
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

      // SỬA: Xử lý null values
      final newItems = response.items ?? [];
      print('✅ Đã tải thêm ${newItems.length} sản phẩm');

      _products = [..._products, ...newItems];
      _totalCount = response.totalCount ?? _totalCount;
      _totalPages = response.totalPages ?? _totalPages;
      _currentPage = nextPage;
      _hasLoaded = true;

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi tải thêm sản phẩm: $e');
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Đảm bảo products đã được load
  Future<void> ensureProductsLoaded() async {
    if (_hasLoaded && _products.isNotEmpty) {
      print('✅ Products đã được load trước đó');
      return;
    }
    
    if (_isFetching || _isLoading) {
      print('⏳ Products đang được load, chờ...');
      while (_isFetching || _isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    await loadProducts();
  }

  // Load products silently (không set loading state)
  Future<void> loadProductsSilently() async {
    if (_hasLoaded) return;
    
    try {
      final response = await _productService.getProductsWithPagination(
        keyword: _searchKeyword,
        categoryId: _selectedCategoryId,
        page: 1,
        pageSize: 10,
      );
      _products = response.items ?? [];
      _totalCount = response.totalCount ?? 0;
      _totalPages = response.totalPages ?? 1;
      _hasLoaded = true;
      notifyListeners();
    } catch (e) {
      print('❌ Load products silently error: $e');
    }
  }

  // Chuyển đến trang
  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _currentPage || _isFetching) {
      print('⚠️ Không thể chuyển trang: page=$page, current=$_currentPage, total=$_totalPages');
      return;
    }
    
    print('🔄 Chuyển đến trang $page');
    _currentPage = page;
    _products = [];
    _hasLoaded = false;
    await loadProducts(refresh: false);
  }

  // Lọc theo danh mục
  Future<void> filterByCategory(String categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    
    _selectedCategoryId = categoryId;
    _searchKeyword = null;
    _currentPage = 1;
    _products = [];
    _hasLoaded = false;
    await loadProducts(refresh: false);
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
    _hasLoaded = false;
    await loadProducts(refresh: false);
  }

  // Refresh danh sách
  Future<void> refreshProducts() async {
    _selectedCategoryId = null;
    _searchKeyword = null;
    _currentPage = 1;
    _products = [];
    _hasLoaded = false;
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

  // Reset state
  void reset() {
    _products = [];
    _featuredProducts = [];
    _newProducts = [];
    _bestSellers = [];
    _isLoading = false;
    _isLoadingMore = false;
    _isFetching = false;
    _error = null;
    _hasLoaded = false;
    _currentPage = 1;
    _totalPages = 1;
    _totalCount = 0;
    _searchKeyword = null;
    _selectedCategoryId = null;
    notifyListeners();
  }

  // Load featured products
  Future<void> loadFeaturedProducts() async {
    try {
      _featuredProducts = await _productService.getFeaturedProducts();
      notifyListeners();
    } catch (e) {
      print('Lỗi tải sản phẩm nổi bật: $e');
    }
  }

  // Load new products
  Future<void> loadNewProducts() async {
    try {
      _newProducts = await _productService.getNewProducts();
      notifyListeners();
    } catch (e) {
      print('Lỗi tải sản phẩm mới: $e');
    }
  }

  // Load best sellers
  Future<void> loadBestSellers() async {
    try {
      _bestSellers = await _productService.getBestSellers();
      notifyListeners();
    } catch (e) {
      print('Lỗi tải sản phẩm bán chạy: $e');
    }
  }

  // Load all products
  Future<void> loadAllProducts() async {
    if (_hasLoaded && _products.isNotEmpty) {
      print('✅ All products đã được load trước đó');
      return;
    }
    
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
      _hasLoaded = true;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get product by id
  Future<Product?> getProductById(String id) async {
    try {
      return await _productService.getProduct(id);
    } catch (e) {
      print('Lỗi lấy chi tiết sản phẩm: $e');
      return null;
    }
  }

  // Tìm sản phẩm trong cache theo ID
  Product? findProductInCache(String productId) {
    try {
      return _products.firstWhere(
        (product) => product.productId == productId,
        orElse: () => null as Product,
      );
    } catch (e) {
      return null;
    }
  }
}
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
  
  // Cache cho từng trang
  Map<int, List<Product>> _pageCache = {};

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

  // Tải danh sách sản phẩm - KHÔNG HIỂN THỊ LOADING
  Future<void> loadProducts({bool refresh = false}) async {
    if (_isFetching && !refresh) {
      print('⏳ Đang fetch products, bỏ qua request');
      return;
    }
    
    // Kiểm tra cache trước
    if (!refresh && _pageCache.containsKey(_currentPage) && _pageCache[_currentPage]!.isNotEmpty) {
      print('✅ Dùng cache cho trang $_currentPage');
      _products = _pageCache[_currentPage]!;
      _hasLoaded = true;
      notifyListeners();
      return;
    }
    
    if (refresh) {
      _currentPage = 1;
      _totalPages = 1;
      _hasLoaded = false;
      _pageCache.clear();
      _products = [];
      notifyListeners();
    }

    if (_isLoading) return;

    _isFetching = true;
    // KHÔNG set _isLoading = true để tránh hiển thị loading
    _error = null;

    try {
      print('🔄 Đang tải sản phẩm trang $_currentPage...');
      
      final response = await _productService.getProductsWithPagination(
        keyword: _searchKeyword,
        categoryId: _selectedCategoryId,
        page: _currentPage,
        pageSize: 10,
      );

      _products = response.items;
      _totalCount = response.totalCount;
      _totalPages = response.totalPages;
      
      // Lưu vào cache
      _pageCache[_currentPage] = List.from(_products);
      
      print('✅ Đã tải ${_products.length} sản phẩm từ trang $_currentPage');
      print('📊 Tổng số trang: $_totalPages, Tổng số sản phẩm: $_totalCount');

      _hasLoaded = true;
      _isFetching = false;
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi tải sản phẩm: $e');
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

      final newItems = response.items;
      print('✅ Đã tải thêm ${newItems.length} sản phẩm');

      _products = [..._products, ...newItems];
      _totalCount = response.totalCount;
      _totalPages = response.totalPages;
      _currentPage = nextPage;
      
      // Lưu vào cache
      _pageCache[nextPage] = List.from(newItems);
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
      _products = response.items;
      _totalCount = response.totalCount;
      _totalPages = response.totalPages;
      _pageCache[1] = List.from(_products);
      _hasLoaded = true;
      notifyListeners();
    } catch (e) {
      print('❌ Load products silently error: $e');
    }
  }

  // Chuyển đến trang - KHÔNG XÓA DỮ LIỆU CŨ, KHÔNG HIỂN THỊ LOADING
  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _currentPage || _isFetching) {
      print('⚠️ Không thể chuyển trang: page=$page, current=$_currentPage, total=$_totalPages');
      return;
    }
    
    print('🔄 Chuyển đến trang $page');
    _currentPage = page;
    
    // Kiểm tra cache
    if (_pageCache.containsKey(page) && _pageCache[page]!.isNotEmpty) {
      print('✅ Dùng cache cho trang $page');
      _products = _pageCache[page]!;
      _hasLoaded = true;
      notifyListeners();
      return;
    }
    
    // Không xóa _products, giữ lại dữ liệu cũ cho đến khi dữ liệu mới về
    // Chỉ gọi load ngầm
    _loadPageInBackground(page);
  }
  
  // Tải trang ngầm trong background
  Future<void> _loadPageInBackground(int page) async {
    if (_isFetching) return;
    
    _isFetching = true;
    
    try {
      print('🔄 Background loading trang $page...');
      
      final response = await _productService.getProductsWithPagination(
        keyword: _searchKeyword,
        categoryId: _selectedCategoryId,
        page: page,
        pageSize: 10,
      );
      
      // Lưu vào cache
      _pageCache[page] = response.items;
      
      // Nếu vẫn đang ở trang này, cập nhật hiển thị
      if (_currentPage == page) {
        _products = response.items;
        notifyListeners();
      }
      
      // Cập nhật tổng số
      _totalCount = response.totalCount;
      _totalPages = response.totalPages;
      
      print('✅ Background loaded trang $page với ${response.items.length} sản phẩm');
    } catch (e) {
      print('❌ Background load error: $e');
    } finally {
      _isFetching = false;
    }
  }

  // Lọc theo danh mục
  Future<void> filterByCategory(String categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    
    _selectedCategoryId = categoryId;
    _searchKeyword = null;
    _currentPage = 1;
    _pageCache.clear();
    _products = [];
    _hasLoaded = false;
    notifyListeners();
    await loadProducts();
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
    _pageCache.clear();
    _products = [];
    _hasLoaded = false;
    notifyListeners();
    await loadProducts();
  }

  // Refresh danh sách
  Future<void> refreshProducts() async {
    _selectedCategoryId = null;
    _searchKeyword = null;
    _currentPage = 1;
    _pageCache.clear();
    _products = [];
    _hasLoaded = false;
    notifyListeners();
    await loadProducts();
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
    _pageCache.clear();
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
      
      await loadProducts();
      
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
    for (var product in _products) {
      if (product.productId == productId) {
        return product;
      }
    }
    return null;
  }
}
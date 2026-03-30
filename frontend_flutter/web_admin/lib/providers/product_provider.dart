import 'dart:io';
import 'package:flutter/foundation.dart'; // Bắt buộc để dùng kIsWeb và Uint8List
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  String? _searchKeyword;
  String? _filterCategoryId;
  
  static const int _pageSize = 9;
  
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  
  void resetToFirstPage() {
    _currentPage = 1;
    _products = [];
  }
  
  Future<void> fetchProducts({bool isLoadMore = false}) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _productService.getProductsWithPagination(
        page: _currentPage,
        pageSize: _pageSize,
        keyword: _searchKeyword,
        categoryId: _filterCategoryId,
      );
      
      if (isLoadMore) {
        _products.addAll(response.items);
      } else {
        _products = response.items;
      }
      _totalCount = response.totalCount;
      _totalPages = response.totalPages;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadMore() async {
    if (_isLoading || _currentPage >= _totalPages) return;
    _currentPage++;
    await fetchProducts(isLoadMore: true);
  }
  
  Future<void> goToPage(int page) async {
    if (page == _currentPage || page < 1 || page > _totalPages) return;
    _currentPage = page;
    await fetchProducts(isLoadMore: false);
  }
  
  Future<void> refreshProducts() async {
    _currentPage = 1;
    await fetchProducts(isLoadMore: false);
  }
  
  Future<void> searchProducts(String keyword) async {
    _searchKeyword = keyword.isEmpty ? null : keyword;
    _currentPage = 1;
    await fetchProducts(isLoadMore: false);
  }
  
  Future<void> filterByCategory(String? categoryId) async {
    _filterCategoryId = categoryId;
    _currentPage = 1;
    await fetchProducts(isLoadMore: false);
  }

  // ========== THÊM/SỬA CÁC HÀM XỬ LÝ DỮ LIỆU ==========

  Future<Product?> getProductById(String productId) async {
    try {
      return await _productService.getProductById(productId);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
  
  Future<bool> createProduct({
    required String productName,
    required String categoryId,
    required String supplierId,
    required String unit,
    required double price,
    required int stockQuantity,
    String? description,
    File? imageFile,      // Cho Mobile
    Uint8List? imageBytes, // Cho Web (Thêm mới)
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newProduct = await _productService.createProduct(
        productName: productName,
        categoryId: categoryId,
        supplierId: supplierId,
        unit: unit,
        price: price,
        stockQuantity: stockQuantity,
        description: description,
        imageFile: imageFile,
        imageBytes: imageBytes, // Truyền dữ liệu byte xuống service
      );
      
      if (newProduct != null) {
        await refreshProducts();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateProduct({
    required String productId,
    required String productName,
    required String categoryId,
    required String supplierId,
    required String unit,
    required double price,
    required int stockQuantity,
    String? description,
    File? imageFile,      // Cho Mobile
    Uint8List? imageBytes, // Cho Web (Thêm mới)
    required bool isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedProduct = await _productService.updateProduct(
        productId: productId,
        productName: productName,
        categoryId: categoryId,
        supplierId: supplierId,
        unit: unit,
        price: price,
        stockQuantity: stockQuantity,
        description: description,
        imageFile: imageFile,
        imageBytes: imageBytes, // Truyền dữ liệu byte xuống service
        isActive: isActive,
      );
      
      if (updatedProduct != null) {
        await refreshProducts();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _productService.deleteProduct(productId);
      if (success) {
        await refreshProducts();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
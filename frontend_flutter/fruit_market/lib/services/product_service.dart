import 'dart:convert';
import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  // Lấy danh sách sản phẩm có phân trang
  Future<PaginatedResponse> getProductsWithPagination({
    String? keyword,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final query = <String, String>{
        'Page': page.toString(),
        'PageSize': pageSize.toString(),
        if (keyword != null && keyword.isNotEmpty) 'Keyword': keyword,
        if (categoryId != null && categoryId.isNotEmpty) 'CategoryId': categoryId,
        if (minPrice != null) 'MinPrice': minPrice.toString(),
        if (maxPrice != null) 'MaxPrice': maxPrice.toString(),
        if (inStock != null) 'InStock': inStock.toString(),
      };

      final uri = Uri.parse('${ApiService.baseUrl}Products')
          .replace(queryParameters: query);
      
      print('🌐 GET: $uri');
      
      final response = await ApiService.get('Products?${uri.query}');
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Response data: currentPage=${data['currentPage']}, totalPages=${data['totalPages']}, totalCount=${data['totalCount']}');
        
        return PaginatedResponse.fromJson(data);
      }
      
      print('❌ Failed to load products: ${response.statusCode}');
      return PaginatedResponse(
        items: [],
        totalCount: 0,
        page: page,
        pageSize: pageSize,
        totalPages: 1,
      );
    } catch (e) {
      print('❌ Error in getProductsWithPagination: $e');
      throw Exception('Lỗi: $e');
    }
  }

  // Lấy danh sách sản phẩm (không phân trang - giữ để tương thích)
  Future<List<Product>> getProducts({
    String? keyword,
    String? categoryId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await getProductsWithPagination(
        keyword: keyword,
        categoryId: categoryId,
        page: page,
        pageSize: pageSize,
      );
      return response.items;
    } catch (e) {
      print('Error in getProducts: $e');
      return [];
    }
  }

  // Lấy chi tiết sản phẩm
  Future<Product?> getProduct(String id) async {
    try {
      final response = await ApiService.get('Products/$id');
      
      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in getProduct: $e');
      return null;
    }
  }

  // Lấy sản phẩm nổi bật
  Future<List<Product>> getFeaturedProducts({int count = 8}) async {
    try {
      final response = await ApiService.get('Products/featured?count=$count');
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getFeaturedProducts: $e');
      return [];
    }
  }

  // Lấy sản phẩm mới
  Future<List<Product>> getNewProducts({int count = 8}) async {
    try {
      final response = await ApiService.get('Products/newest?count=$count');
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getNewProducts: $e');
      return [];
    }
  }

  // Lấy sản phẩm bán chạy
  Future<List<Product>> getBestSellers({int count = 8}) async {
    try {
      final response = await ApiService.get('Products/bestselling?count=$count');
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getBestSellers: $e');
      return [];
    }
  }

  // Tìm kiếm sản phẩm
  Future<List<Product>> searchProducts(String keyword) async {
    if (keyword.isEmpty) return [];
    try {
      final response = await ApiService.get('Products/search/name?keyword=$keyword');
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error in searchProducts: $e');
      return [];
    }
  }

  // Lấy sản phẩm theo danh mục
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await ApiService.get('Products/category/$categoryId');
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getProductsByCategory: $e');
      return [];
    }
  }

  // Kiểm tra còn hàng
  Future<bool> checkStock(String id, {int quantity = 1}) async {
    try {
      final response = await ApiService.get('Products/$id/instock?quantity=$quantity');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['inStock'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Tạo sản phẩm mới (admin)
  Future<Product?> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await ApiService.post('Products', body: productData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Product.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in createProduct: $e');
      return null;
    }
  }

  // Cập nhật sản phẩm (admin)
  Future<Product?> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      final response = await ApiService.put('Products/$id', body: productData);
      
      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error in updateProduct: $e');
      return null;
    }
  }

  // Xóa sản phẩm (admin)
  Future<bool> deleteProduct(String id) async {
    try {
      final response = await ApiService.delete('Products/$id');
      return response.statusCode == 200;
    } catch (e) {
      print('Error in deleteProduct: $e');
      return false;
    }
  }
}

// Model phân trang
class PaginatedResponse {
  final List<Product> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => Product.fromJson(e))
          .toList(),
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'totalCount': totalCount,
      'page': page,
      'pageSize': pageSize,
      'totalPages': totalPages,
    };
  }
}
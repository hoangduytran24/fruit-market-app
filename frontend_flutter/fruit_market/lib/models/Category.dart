import 'product.dart';

class Category {
  final String categoryId;
  final String categoryName;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;
  final int productCount;

  /// nếu API trả luôn danh sách sản phẩm (có thể có hoặc không)
  final List<Product>? products;

  Category({
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.imageUrl,
    required this.createdAt,
    required this.productCount,
    this.products,
  });

  /// JSON -> Object
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],           // THÊM: lấy imageUrl
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      productCount: json['productCount'] ?? 0, // THÊM: lấy productCount
      products: json['products'] != null
          ? (json['products'] as List)
              .map((e) => Product.fromJson(e))
              .toList()
          : null,
    );
  }

  /// Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'imageUrl': imageUrl,                   // THÊM imageUrl
      'createdAt': createdAt.toIso8601String(),
      'productCount': productCount,            // THÊM productCount
      'products': products?.map((e) => e.toJson()).toList(),
    };
  }
}
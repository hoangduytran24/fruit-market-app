class Product {
  final String productId;
  final String productName;
  final String? categoryId;
  final String? categoryName;
  final String? supplierId;
  final String? supplierName;
  final String unit;
  final double price;
  final int stockQuantity;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final double averageRating;
  final int reviewCount;

  Product({
    required this.productId,
    required this.productName,
    this.categoryId,
    this.categoryName,
    this.supplierId,
    this.supplierName,
    required this.unit,
    required this.price,
    required this.stockQuantity,
    this.description,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
    this.averageRating = 0,
    this.reviewCount = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      supplierId: json['supplierId'],
      supplierName: json['supplierName'],
      unit: json['unit'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
      description: json['description'],
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'unit': unit,
      'price': price,
      'stockQuantity': stockQuantity,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }
}
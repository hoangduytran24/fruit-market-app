class Product {
  final String productId;
  final String categoryId;
  final String supplierId;
  final String productName;
  final String unit;
  final double price;
  final int stockQuantity;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final String? categoryName; // THÊM DÒNG NÀY

  Product({
    required this.productId,
    required this.categoryId,
    required this.supplierId,
    required this.productName,
    required this.unit,
    required this.price,
    required this.stockQuantity,
    this.description,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
    this.categoryName, 
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      supplierId: json['supplierId'] ?? '',
      productName: json['productName'] ?? '',
      unit: json['unit'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
      description: json['description'],
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      categoryName: json['categoryName'], // THÊM DÒNG NÀY
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'categoryId': categoryId,
      'supplierId': supplierId,
      'productName': productName,
      'unit': unit,
      'price': price,
      'stockQuantity': stockQuantity,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'categoryName': categoryName,
    };
  }
}
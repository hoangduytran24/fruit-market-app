class Favorite{
  final String favoriteId;
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice; // API trả về decimal -> double trong Flutter
  final String productUnit;
  final DateTime createdAt;

  Favorite({
    required this.favoriteId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.productUnit,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      favoriteId: json['favoriteId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      productPrice: (json['productPrice'] ?? 0).toDouble(),
      productUnit: json['productUnit'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favoriteId': favoriteId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'productUnit': productUnit,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
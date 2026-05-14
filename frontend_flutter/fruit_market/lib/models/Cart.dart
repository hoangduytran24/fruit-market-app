import 'CartItem.dart';

class Cart {
  final String cartId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CartItem> items;
  final int totalItems;
  final double totalPrice;
  final bool hasAutoCorrected; // ✅ Thêm flag này

  Cart({
    required this.cartId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.totalItems,
    required this.totalPrice,
    this.hasAutoCorrected = false, // ✅ Mặc định là false
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      cartId: json['cartId'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => CartItem.fromJson(e))
              .toList()
          : [],
      totalItems: json['totalItems'] ?? 0,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      hasAutoCorrected: json['hasAutoCorrected'] ?? false, // ✅ Parse flag
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartId': cartId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
      'totalItems': totalItems,
      'totalPrice': totalPrice,
      'hasAutoCorrected': hasAutoCorrected, // ✅ Thêm vào toJson
    };
  }
}
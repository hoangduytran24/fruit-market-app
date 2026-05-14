import 'product.dart';

class CartItem {
  final String cartItemId;
  final String productId;
  final String productName;
  final String? imageUrl;
  final String unit;
  final double price;
  final int quantity;
  final double subtotal;
  final int stockQuantity;
  final Product? product;

  CartItem({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.unit,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.stockQuantity,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cartItemId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      imageUrl: json['imageUrl'],
      unit: json['unit'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,  // THÊM: Lấy từ API hoặc product
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartItemId': cartItemId,
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'unit': unit,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      'stockQuantity': stockQuantity,  // THÊM
      'product': product?.toJson(),
    };
  }
}
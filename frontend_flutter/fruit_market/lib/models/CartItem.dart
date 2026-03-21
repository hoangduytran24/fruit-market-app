import 'product.dart';

class CartItem {
  final String cartItemId;
  final String productId;
  final String productName;  // THÊM
  final String? imageUrl;     // THÊM
  final String unit;          // THÊM
  final double price;         // API trả về "price"
  final int quantity;
  final double subtotal;      // THÊM
  final Product? product;     // Giữ lại nếu có

  CartItem({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.unit,
    required this.price,
    required this.quantity,
    required this.subtotal,
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
      'product': product?.toJson(),
    };
  }
}
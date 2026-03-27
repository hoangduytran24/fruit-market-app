import 'product.dart';
class OrderItem {
  final String orderItemId;
  final String orderId;
  final String productId;
  final String productName;  // THÊM
  final String? imageUrl;    // THÊM
  final int quantity;
  final double priceAtTime;
  final double subtotal;

  /// nếu API trả luôn product
  final Product? product;

  OrderItem({
    required this.orderItemId,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.quantity,
    required this.priceAtTime,
    required this.subtotal,
    this.product,
  });

  /// JSON -> Object
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderItemId: json['orderItemId'] ?? '',
      orderId: json['orderId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      imageUrl: json['imageUrl'],
      quantity: json['quantity'] ?? 0,
      priceAtTime: (json['price'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }

  /// Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      'orderItemId': orderItemId,
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'priceAtTime': priceAtTime,
      'subtotal': subtotal,
      'product': product?.toJson(),
    };
  }
}
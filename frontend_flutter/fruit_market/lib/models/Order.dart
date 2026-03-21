import 'OrderItem.dart';

class Order {
  final String orderId;
  final String userId;
  final String customerName;      // THÊM
  final String? customerPhone;    // THÊM
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String status;
  final String? paymentMethod;
  final String deliveryAddress;
  final DateTime createdAt;
  final List<OrderItem>? items;   // SỬA: orderItems -> items
  final String? voucherCode;      // THÊM

  Order({
    required this.orderId,
    required this.userId,
    required this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.status,
    this.paymentMethod,
    required this.deliveryAddress,
    required this.createdAt,
    this.items,
    this.voucherCode,
  });

  /// JSON -> Object
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'],
      deliveryAddress: json['deliveryAddress'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => OrderItem.fromJson(e))
              .toList()
          : null,
      voucherCode: json['voucherCode'],
    );
  }

  /// Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress,
      'createdAt': createdAt.toIso8601String(),
      'items': items?.map((e) => e.toJson()).toList(),
      'voucherCode': voucherCode,
    };
  }
}
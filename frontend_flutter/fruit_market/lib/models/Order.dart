import 'OrderItem.dart';

class Order {
  final String orderId;
  final String userId;
  final String customerName;
  final String? customerPhone;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String status;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? paymentId;
  final String deliveryAddress;
  final String receiverName;
  final String receiverPhone;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<OrderItem>? items;
  final String? voucherCode;

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
    this.paymentStatus,
    this.paymentId,
    required this.deliveryAddress,
    required this.receiverName,
    required this.receiverPhone,
    required this.createdAt,
    this.completedAt,
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
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      paymentId: json['paymentId'],
      deliveryAddress: json['deliveryAddress'] ?? '',
      receiverName: json['receiverName'] ?? '',
      receiverPhone: json['receiverPhone'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      completedAt: json['completedAt'] != null  
          ? DateTime.parse(json['completedAt']) 
          : null,
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
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'deliveryAddress': deliveryAddress,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'items': items?.map((e) => e.toJson()).toList(),
      'voucherCode': voucherCode,
    };
  }
}
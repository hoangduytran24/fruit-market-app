import 'order.dart';

class Payment {
  final String paymentId;
  final String orderId;
  final double amount;
  final String? paymentMethod;
  final String paymentStatus;
  final String? transactionCode;
  final DateTime? paidAt;

  final Order? order;

  Payment({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    this.paymentMethod,
    required this.paymentStatus,
    this.transactionCode,
    this.paidAt,
    this.order,
  });

  /// JSON -> Object
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentId: json['paymentId'],
      orderId: json['orderId'],
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      transactionCode: json['transactionCode'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      order: json['order'] != null ? Order.fromJson(json['order']) : null,
    );
  }

  /// Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'transactionCode': transactionCode,
      'paidAt': paidAt?.toIso8601String(),
      'order': order?.toJson(),
    };
  }
}
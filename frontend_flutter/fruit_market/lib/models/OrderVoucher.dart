import 'Voucher.dart';

class OrderVoucher {
  final String orderVoucherId;
  final String orderId;
  final String voucherId;
  final double discountAmount;

  /// nếu API trả luôn voucher
  final Voucher? voucher;

  OrderVoucher({
    required this.orderVoucherId,
    required this.orderId,
    required this.voucherId,
    required this.discountAmount,
    this.voucher,
  });

  /// JSON -> Object
  factory OrderVoucher.fromJson(Map<String, dynamic> json) {
    return OrderVoucher(
      orderVoucherId: json['orderVoucherId'],
      orderId: json['orderId'],
      voucherId: json['voucherId'],
      discountAmount: (json['discountAmount'] as num).toDouble(),
      voucher:
          json['voucher'] != null ? Voucher.fromJson(json['voucher']) : null,
    );
  }

  /// Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      'orderVoucherId': orderVoucherId,
      'orderId': orderId,
      'voucherId': voucherId,
      'discountAmount': discountAmount,
      'voucher': voucher?.toJson(),
    };
  }
}
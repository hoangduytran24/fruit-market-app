class Voucher {
  final String voucherId;
  final String voucherCode;
  final String discountType;
  final double discountValue;
  final double minOrderValue;
  final double? maxDiscountValue;
  final int quantity;
  final int usedQuantity;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final bool isValid;

  Voucher({
    required this.voucherId,
    required this.voucherCode,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    this.maxDiscountValue,
    required this.quantity,
    required this.usedQuantity,
    this.startDate,
    this.endDate,
    required this.status,
    required this.isValid,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      voucherId: json['voucherId'] ?? '',
      voucherCode: json['voucherCode'] ?? '',
      discountType: json['discountType'] ?? '',
      discountValue: (json['discountValue'] as num).toDouble(),
      minOrderValue: (json['minOrderValue'] as num).toDouble(),
      maxDiscountValue: json['maxDiscountValue'] != null 
          ? (json['maxDiscountValue'] as num).toDouble() 
          : null,
      quantity: json['quantity'] ?? 0,
      usedQuantity: json['usedQuantity'] ?? 0,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: json['status'] ?? 'inactive',
      isValid: json['isValid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voucherCode': voucherCode,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'maxDiscountValue': maxDiscountValue,
      'quantity': quantity,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
    };
  }
}
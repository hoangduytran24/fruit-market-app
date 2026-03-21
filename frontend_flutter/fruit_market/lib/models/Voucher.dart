import 'package:intl/intl.dart';

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
  });

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
        voucherId: json['voucherId'],
        voucherCode: json['voucherCode'],
        discountType: json['discountType'],
        discountValue: (json['discountValue'] as num).toDouble(),
        minOrderValue: (json['minOrderValue'] as num).toDouble(),
        maxDiscountValue: json['maxDiscountValue'] != null
            ? (json['maxDiscountValue'] as num).toDouble()
            : null,
        quantity: json['quantity'],
        usedQuantity: json['usedQuantity'],
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'])
            : null,
        endDate:
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        status: json['status'],
      );

  Map<String, dynamic> toJson() => {
        'voucherId': voucherId,
        'voucherCode': voucherCode,
        'discountType': discountType,
        'discountValue': discountValue,
        'minOrderValue': minOrderValue,
        'maxDiscountValue': maxDiscountValue,
        'quantity': quantity,
        'usedQuantity': usedQuantity,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'status': status,
      };
}

// DTO cho voucher public
class VoucherPublicDto {
  final String voucherId;
  final String voucherCode;
  final String discountType;
  final double discountValue;
  final double minOrderValue;
  final double? maxDiscountValue;
  final DateTime? startDate;
  final DateTime? endDate;
  final String description;
  final int remainingCount;

  VoucherPublicDto({
    required this.voucherId,
    required this.voucherCode,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    this.maxDiscountValue,
    this.startDate,
    this.endDate,
    required this.description,
    required this.remainingCount,
  });

  // Thêm getter isExpired
  bool get isExpired {
    if (endDate == null) return false;
    return endDate!.isBefore(DateTime.now());
  }

  // Thêm getter isExpiring (sắp hết hạn trong 3 ngày)
  bool get isExpiring {
    if (endDate == null) return false;
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));
    return endDate!.isBefore(threeDaysLater) && !isExpired;
  }

  // Thêm method formatDate
  String formatDate(DateTime? date) {
    if (date == null) return 'Không giới hạn';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  factory VoucherPublicDto.fromJson(Map<String, dynamic> json) =>
      VoucherPublicDto(
        voucherId: json['voucherId'],
        voucherCode: json['voucherCode'],
        discountType: json['discountType'],
        discountValue: (json['discountValue'] as num).toDouble(),
        minOrderValue: (json['minOrderValue'] as num).toDouble(),
        maxDiscountValue: json['maxDiscountValue'] != null
            ? (json['maxDiscountValue'] as num).toDouble()
            : null,
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'])
            : null,
        endDate:
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        description: json['description'],
        remainingCount: json['remainingCount'],
      );

  Map<String, dynamic> toJson() => {
        'voucherId': voucherId,
        'voucherCode': voucherCode,
        'discountType': discountType,
        'discountValue': discountValue,
        'minOrderValue': minOrderValue,
        'maxDiscountValue': maxDiscountValue,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'description': description,
        'remainingCount': remainingCount,
      };
}

// DTO cho kết quả áp dụng voucher
class VoucherResultDto {
  final bool isValid;
  final String message;
  final double discountAmount;
  final double finalAmount;
  final VoucherPublicDto? voucher;

  VoucherResultDto({
    required this.isValid,
    required this.message,
    required this.discountAmount,
    required this.finalAmount,
    this.voucher,
  });

  factory VoucherResultDto.fromJson(Map<String, dynamic> json) =>
      VoucherResultDto(
        isValid: json['isValid'],
        message: json['message'],
        discountAmount: (json['discountAmount'] as num).toDouble(),
        finalAmount: (json['finalAmount'] as num).toDouble(),
        voucher: json['voucher'] != null
            ? VoucherPublicDto.fromJson(json['voucher'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'message': message,
        'discountAmount': discountAmount,
        'finalAmount': finalAmount,
        'voucher': voucher?.toJson(),
      };
}
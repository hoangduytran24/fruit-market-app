import 'Voucher.dart';

class UserVoucher {
  final String userVoucherId;
  final String userId;
  final String voucherId;
  final DateTime savedAt;
  final DateTime? usedAt;
  final bool isUsed;
  final VoucherPublicDto? voucher; // Đổi từ Voucher thành VoucherPublicDto

  UserVoucher({
    required this.userVoucherId,
    required this.userId,
    required this.voucherId,
    required this.savedAt,
    this.usedAt,
    required this.isUsed,
    this.voucher,
  });

  /// JSON -> Object
  factory UserVoucher.fromJson(Map<String, dynamic> json) {
    return UserVoucher(
      userVoucherId: json['userVoucherId'],
      userId: json['userId'],
      voucherId: json['voucherId'],
      savedAt: DateTime.parse(json['savedAt']),
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
      isUsed: json['isUsed'],
      voucher: json['voucher'] != null 
          ? VoucherPublicDto.fromJson(json['voucher']) // Đổi thành VoucherPublicDto
          : null,
    );
  }

  /// Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      'userVoucherId': userVoucherId,
      'userId': userId,
      'voucherId': voucherId,
      'savedAt': savedAt.toIso8601String(),
      'usedAt': usedAt?.toIso8601String(),
      'isUsed': isUsed,
      'voucher': voucher?.toJson(),
    };
  }
}
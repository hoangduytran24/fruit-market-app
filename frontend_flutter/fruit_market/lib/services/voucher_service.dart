import 'dart:convert';
import '../models/Voucher.dart';
import '../models/user_voucher.dart';
import 'api_service.dart';

class VoucherService {
  final ApiService _apiService = ApiService();

  /// Lấy danh sách voucher khả dụng (không cần đăng nhập)
  Future<List<VoucherPublicDto>> getAvailableVouchers() async {
    try {
      final response = await ApiService.getPublic('vouchers/available');
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => VoucherPublicDto.fromJson(json)).toList();
    } catch (e) {
      print('❌ Lỗi lấy voucher khả dụng: $e');
      rethrow;
    }
  }

  /// Áp dụng voucher (cần đăng nhập)
  Future<VoucherResultDto> applyVoucher(String voucherCode, double orderTotal) async {
    try {
      final body = {
        'voucherCode': voucherCode,
        'orderTotal': orderTotal,
      };
      final response = await ApiService.post('vouchers/apply', body: body);
      final data = json.decode(response.body);
      return VoucherResultDto.fromJson(data);
    } catch (e) {
      print('❌ Lỗi áp dụng voucher: $e');
      rethrow;
    }
  }

  /// Lưu voucher cho user (cần đăng nhập)
  Future<void> saveVoucher(String voucherCode) async {
    try {
      final body = {
        'voucherCode': voucherCode,
      };
      await ApiService.post('vouchers/save', body: body);
    } catch (e) {
      print('❌ Lỗi lưu voucher: $e');
      rethrow;
    }
  }

  /// Lấy danh sách voucher đã lưu của user (cần đăng nhập)
  Future<List<UserVoucher>> getMySavedVouchers() async {
    try {
      final response = await ApiService.get('vouchers/my-vouchers');
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => UserVoucher.fromJson(json)).toList();
    } catch (e) {
      print('❌ Lỗi lấy voucher đã lưu: $e');
      rethrow;
    }
  }

  /// Sử dụng voucher đã lưu (cần đăng nhập)
  Future<void> useSavedVoucher(String userVoucherId) async {
    try {
      await ApiService.post('vouchers/use/$userVoucherId');
    } catch (e) {
      print('❌ Lỗi sử dụng voucher: $e');
      rethrow;
    }
  }
}
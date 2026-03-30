import 'dart:convert';
import '../models/voucher.dart';
import 'api_service.dart'; // Đảm bảo đúng đường dẫn file ApiService của bạn

class AdminVoucherService {
  static const String _endpoint = 'vouchers';

  // Lấy toàn bộ danh sách voucher (Admin)
  Future<List<Voucher>> getAllVouchers() async {
    final response = await ApiService.get(_endpoint);
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Voucher.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi khi lấy danh sách voucher');
    }
  }

  // Tạo mới voucher
  Future<Voucher> createVoucher(Voucher voucher) async {
    final response = await ApiService.post(_endpoint, body: voucher.toJson());
    if (response.statusCode == 201) {
      return Voucher.fromJson(json.decode(response.body));
    } else {
      final msg = json.decode(response.body)['message'] ?? 'Không thể tạo voucher';
      throw Exception(msg);
    }
  }

  // Cập nhật voucher
  Future<Voucher> updateVoucher(String id, Voucher voucher) async {
    final response = await ApiService.put('$_endpoint/$id', body: voucher.toJson());
    if (response.statusCode == 200) {
      return Voucher.fromJson(json.decode(response.body));
    } else {
      throw Exception('Cập nhật voucher thất bại');
    }
  }

  // Bật/Tắt trạng thái voucher
  Future<bool> toggleStatus(String id) async {
    final response = await ApiService.patch('$_endpoint/$id/status');
    return response.statusCode == 200;
  }

  // Xóa voucher
  Future<bool> deleteVoucher(String id) async {
    final response = await ApiService.delete('$_endpoint/$id');
    return response.statusCode == 200;
  }
}
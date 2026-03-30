import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../services/voucher_service.dart';

class AdminVoucherProvider with ChangeNotifier {
  final AdminVoucherService _service = AdminVoucherService();
  
  List<Voucher> _vouchers = [];
  bool _isLoading = false;

  List<Voucher> get vouchers => _vouchers;
  bool get isLoading => _isLoading;

  // Tải danh sách
  Future<void> fetchVouchers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _vouchers = await _service.getAllVouchers();
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xử lý bật tắt nhanh trên UI
  Future<void> toggleVoucherStatus(String id) async {
    try {
      final success = await _service.toggleStatus(id);
      if (success) {
        // Cập nhật local state để UI thay đổi ngay lập tức
        int index = _vouchers.indexWhere((v) => v.voucherId == id);
        if (index != -1) {
          String newStatus = _vouchers[index].status == 'active' ? 'inactive' : 'active';
          // Tạo bản sao mới với status thay đổi (vì model thường là immutable)
          _vouchers[index] = Voucher.fromJson({
            ..._vouchers[index].toJson(), // Lưu ý: cần map lại đầy đủ các trường
            'status': newStatus,
            'voucherId': id,
            'usedQuantity': _vouchers[index].usedQuantity,
            'isValid': newStatus == 'active'
          });
          notifyListeners();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Xóa voucher
  Future<void> deleteVoucher(String id) async {
    try {
      final success = await _service.deleteVoucher(id);
      if (success) {
        _vouchers.removeWhere((v) => v.voucherId == id);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Thêm mới voucher
  Future<void> createVoucher(Voucher voucher) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newVoucher = await _service.createVoucher(voucher);
      _vouchers.insert(0, newVoucher); // Thêm voucher mới vào đầu danh sách hiển thị
      notifyListeners();
    } catch (e) {
      print("Lỗi tại Provider khi tạo voucher: $e");
      rethrow; // Ném lỗi để UI (SnackBar) có thể bắt được và hiển thị
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // (Tùy chọn) Thêm hàm cập nhật voucher nếu bạn muốn dùng nút "Lưu thay đổi"
  Future<void> updateVoucher(String id, Voucher voucher) async {
    try {
      final updated = await _service.updateVoucher(id, voucher);
      int index = _vouchers.indexWhere((v) => v.voucherId == id);
      if (index != -1) {
        _vouchers[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      print("Lỗi khi cập nhật: $e");
      rethrow;
    }
  }
}
import 'package:flutter/material.dart';
import '../models/Voucher.dart';
import '../models/user_voucher.dart';
import '../services/voucher_service.dart';

class VoucherProvider extends ChangeNotifier {
  final VoucherService _voucherService = VoucherService();
  
  List<VoucherPublicDto> _availableVouchers = [];
  List<UserVoucher> _savedVouchers = [];
  bool _isLoading = false;
  bool _isLoadingSaved = false;
  String? _error;
  String? _savedError;
  VoucherResultDto? _appliedVoucher;

  // Getters
  List<VoucherPublicDto> get availableVouchers => _availableVouchers;
  List<UserVoucher> get savedVouchers => _savedVouchers;
  bool get isLoading => _isLoading;
  bool get isLoadingSaved => _isLoadingSaved;
  String? get error => _error;
  String? get savedError => _savedError;
  VoucherResultDto? get appliedVoucher => _appliedVoucher;

  // Lấy danh sách voucher khả dụng
  Future<void> loadAvailableVouchers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availableVouchers = await _voucherService.getAvailableVouchers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy danh sách voucher đã lưu
  Future<void> loadSavedVouchers() async {
    _isLoadingSaved = true;
    _savedError = null;
    notifyListeners();

    try {
      _savedVouchers = await _voucherService.getMySavedVouchers();
    } catch (e) {
      _savedError = e.toString();
    } finally {
      _isLoadingSaved = false;
      notifyListeners();
    }
  }

  // Lưu voucher
  Future<bool> saveVoucher(String voucherCode) async {
    try {
      await _voucherService.saveVoucher(voucherCode);
      await loadSavedVouchers(); // Refresh danh sách đã lưu
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Áp dụng voucher
  Future<bool> applyVoucher(String voucherCode, double orderTotal) async {
    try {
      _appliedVoucher = await _voucherService.applyVoucher(voucherCode, orderTotal);
      notifyListeners();
      return _appliedVoucher?.isValid ?? false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sử dụng voucher đã lưu
  Future<bool> useSavedVoucher(String userVoucherId) async {
    try {
      await _voucherService.useSavedVoucher(userVoucherId);
      await loadSavedVouchers(); // Refresh danh sách
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Xóa kết quả áp dụng voucher
  void clearAppliedVoucher() {
    _appliedVoucher = null;
    notifyListeners();
  }

  // Reset lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
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
  
  bool _hasLoadedAvailable = false;
  bool _hasLoadedSaved = false;
  bool _isFetchingAvailable = false;
  bool _isFetchingSaved = false;

  // Getters
  List<VoucherPublicDto> get availableVouchers => _availableVouchers;
  List<UserVoucher> get savedVouchers => _savedVouchers;
  bool get isLoading => _isLoading;
  bool get isLoadingSaved => _isLoadingSaved;
  String? get error => _error;
  String? get savedError => _savedError;
  VoucherResultDto? get appliedVoucher => _appliedVoucher;
  bool get hasLoadedAvailable => _hasLoadedAvailable;
  bool get hasLoadedSaved => _hasLoadedSaved;
  bool get hasAvailableVouchers => _availableVouchers.isNotEmpty;
  bool get hasSavedVouchers => _savedVouchers.isNotEmpty;

  // Lấy danh sách voucher khả dụng
  Future<void> loadAvailableVouchers({bool forceRefresh = false}) async {
    if (_isFetchingAvailable) {
      print('⏳ Đang fetch available vouchers, bỏ qua request');
      return;
    }
    
    if (_hasLoadedAvailable && !forceRefresh) {
      print('✅ Đã load available vouchers trước đó, bỏ qua fetch');
      return;
    }

    _isFetchingAvailable = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availableVouchers = await _voucherService.getAvailableVouchers();
      _hasLoadedAvailable = true;
    } catch (e) {
      _error = e.toString();
      _hasLoadedAvailable = false;
    } finally {
      _isLoading = false;
      _isFetchingAvailable = false;
      notifyListeners();
    }
  }

  // Lấy danh sách voucher đã lưu
  Future<void> loadSavedVouchers({bool forceRefresh = false}) async {
    if (_isFetchingSaved) {
      print('⏳ Đang fetch saved vouchers, bỏ qua request');
      return;
    }
    
    if (_hasLoadedSaved && !forceRefresh) {
      print('✅ Đã load saved vouchers trước đó, bỏ qua fetch');
      return;
    }

    _isFetchingSaved = true;
    _isLoadingSaved = true;
    _savedError = null;
    notifyListeners();

    try {
      _savedVouchers = await _voucherService.getMySavedVouchers();
      _hasLoadedSaved = true;
    } catch (e) {
      _savedError = e.toString();
      _hasLoadedSaved = false;
    } finally {
      _isLoadingSaved = false;
      _isFetchingSaved = false;
      notifyListeners();
    }
  }

  // Đảm bảo available vouchers đã được load
  Future<void> ensureAvailableVouchersLoaded() async {
    if (_hasLoadedAvailable) {
      print('✅ Available vouchers đã được load trước đó');
      return;
    }
    
    if (_isFetchingAvailable || _isLoading) {
      print('⏳ Available vouchers đang được load, chờ...');
      while (_isFetchingAvailable || _isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    await loadAvailableVouchers();
  }

  // Đảm bảo saved vouchers đã được load
  Future<void> ensureSavedVouchersLoaded() async {
    if (_hasLoadedSaved) {
      print('✅ Saved vouchers đã được load trước đó');
      return;
    }
    
    if (_isFetchingSaved || _isLoadingSaved) {
      print('⏳ Saved vouchers đang được load, chờ...');
      while (_isFetchingSaved || _isLoadingSaved) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    await loadSavedVouchers();
  }

  // Load available vouchers silently
  Future<void> loadAvailableVouchersSilently() async {
    if (_hasLoadedAvailable) return;
    
    try {
      _availableVouchers = await _voucherService.getAvailableVouchers();
      _hasLoadedAvailable = true;
      notifyListeners();
    } catch (e) {
      print('❌ Load available vouchers silently error: $e');
    }
  }

  // Load saved vouchers silently
  Future<void> loadSavedVouchersSilently() async {
    if (_hasLoadedSaved) return;
    
    try {
      _savedVouchers = await _voucherService.getMySavedVouchers();
      _hasLoadedSaved = true;
      notifyListeners();
    } catch (e) {
      print('❌ Load saved vouchers silently error: $e');
    }
  }

  // Lưu voucher
  Future<bool> saveVoucher(String voucherCode) async {
    try {
      await _voucherService.saveVoucher(voucherCode);
      await loadSavedVouchers(forceRefresh: true);
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
      await loadSavedVouchers(forceRefresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Làm mới dữ liệu (force refresh)
  Future<void> refreshAvailableVouchers() async {
    await loadAvailableVouchers(forceRefresh: true);
  }

  Future<void> refreshSavedVouchers() async {
    await loadSavedVouchers(forceRefresh: true);
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

  // Reset toàn bộ state
  void reset() {
    _availableVouchers = [];
    _savedVouchers = [];
    _isLoading = false;
    _isLoadingSaved = false;
    _error = null;
    _savedError = null;
    _appliedVoucher = null;
    _hasLoadedAvailable = false;
    _hasLoadedSaved = false;
    _isFetchingAvailable = false;
    _isFetchingSaved = false;
    notifyListeners();
  }

  // Tìm voucher theo mã - ĐÃ SỬA
  VoucherPublicDto? findAvailableVoucherByCode(String code) {
    for (var voucher in _availableVouchers) {
      if (voucher.voucherCode == code) {
        return voucher;
      }
    }
    return null;
  }

  // Lấy voucher đã lưu theo ID - ĐÃ SỬA
  UserVoucher? findSavedVoucherById(String userVoucherId) {
    for (var userVoucher in _savedVouchers) {
      if (userVoucher.userVoucherId == userVoucherId) {
        return userVoucher;
      }
    }
    return null;
  }

  // Lấy danh sách voucher hợp lệ (chưa hết hạn)
  List<UserVoucher> getValidSavedVouchers() {
    final now = DateTime.now();
    return _savedVouchers.where((uv) {
      final voucher = uv.voucher;
      if (voucher == null) return false;
      if (uv.isUsed) return false;
      if (voucher.endDate != null && now.isAfter(voucher.endDate!)) return false;
      return true;
    }).toList();
  }

  // Lấy danh sách voucher có thể áp dụng cho đơn hàng
  List<UserVoucher> getApplicableVouchers(double orderTotal) {
    final validVouchers = getValidSavedVouchers();
    return validVouchers.where((uv) {
      final voucher = uv.voucher;
      if (voucher == null) return false;
      return orderTotal >= voucher.minOrderValue;
    }).toList();
  }
}
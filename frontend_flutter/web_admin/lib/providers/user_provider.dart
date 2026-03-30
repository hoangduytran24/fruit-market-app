import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  List<User> _allFilteredUsers = [];
  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  String? _searchKeyword;
  String? _filterRole;

  int _currentPage = 1;
  static const int _pageSize = 8;

  // --- Getters ---
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  
  int get totalPages {
    if (_allFilteredUsers.isEmpty) return 1;
    return (_allFilteredUsers.length / _pageSize).ceil();
  }

  /// Tải dữ liệu từ server
  Future<void> fetchUsers({String? keyword, String? role}) async {
    _isLoading = true;
    _errorMessage = null;
    
    if (keyword != null) _searchKeyword = keyword;
    if (role != null) _filterRole = role;
    
    notifyListeners();

    try {
      final List<User> results = await _userService.getUsers(
        keyword: _searchKeyword, 
        role: _filterRole == 'Tất cả' ? null : _filterRole
      );

      if (_searchKeyword != null && _searchKeyword!.isNotEmpty) {
        _allFilteredUsers = results.where((u) => 
          u.fullName.toLowerCase().contains(_searchKeyword!.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchKeyword!.toLowerCase())
        ).toList();
      } else {
        _allFilteredUsers = results;
      }

      _paginate();
    } catch (e) {
      _errorMessage = e.toString();
      _allFilteredUsers = [];
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _paginate() {
    final int start = (_currentPage - 1) * _pageSize;
    int end = start + _pageSize;
    
    if (end > _allFilteredUsers.length) end = _allFilteredUsers.length;

    if (start < _allFilteredUsers.length) {
      _users = _allFilteredUsers.sublist(start, end);
    } else {
      _users = [];
      if (_currentPage > 1) {
        _currentPage = 1;
        _paginate();
      }
    }
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages) return;
    _currentPage = page;
    _paginate();
    notifyListeners();
  }

  void searchUsers(String keyword) {
    _searchKeyword = keyword.trim();
    _currentPage = 1;
    fetchUsers();
  }

  void filterByRole(String? role) {
    _filterRole = role;
    _currentPage = 1;
    fetchUsers();
  }

  Future<bool> addAdmin(String name, String email, String password, String? phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _userService.createAdmin(
        fullName: name, 
        email: email, 
        password: password, 
        phone: phone
      );
      await fetchUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== SỬA LẠI HÀM NÀY ====================
  Future<bool> toggleUserStatus(String userId, String currentStatus) async {
    try {
      // Chuyển đổi đúng status theo backend
      // Backend chấp nhận: 'active', 'inactive', 'banned'
      String newStatus;
      if (currentStatus == 'active') {
        newStatus = 'banned';  // Khóa tài khoản (banned = cấm vĩnh viễn)
      } else {
        newStatus = 'active';  // Mở khóa
      }
      
      await _userService.updateUserStatus(userId, newStatus);
      
      // Tải lại danh sách sau khi cập nhật
      await fetchUsers(); 
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
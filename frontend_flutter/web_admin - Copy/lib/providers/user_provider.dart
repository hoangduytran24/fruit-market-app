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

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  
  int get totalPages {
    if (_allFilteredUsers.isEmpty) return 1;
    return (_allFilteredUsers.length / _pageSize).ceil();
  }

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
      _allFilteredUsers = results;
      _paginate();
    } catch (e) {
      _errorMessage = e.toString();
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

  // --- HÀM ADD ADMIN ĐÃ CẬP NHẬT ---
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
      rethrow; // Quan trọng: Đẩy lỗi này ra để Screen bắt được
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleUserStatus(String userId, String currentStatus) async {
    try {
      String newStatus = (currentStatus == 'active') ? 'banned' : 'active';
      await _userService.updateUserStatus(userId, newStatus);
      await fetchUsers(); 
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';

class UserService {
  // 1. Lấy danh sách + Tìm kiếm + Lọc theo Role
  Future<List<User>> getUsers({String? keyword, String? role}) async {
    String endpoint = 'UserManagement/all';
    
    // Ưu tiên dùng endpoint search nếu có keyword
    if (keyword != null && keyword.isNotEmpty) {
      endpoint = 'UserManagement/search?keyword=$keyword';
    }

    if (role != null && role != 'Tất cả' && role.isNotEmpty) {
      endpoint += (endpoint.contains('?') ? '&' : '?') + 'role=$role';
    }

    final response = await ApiService.get(endpoint);

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => User.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách người dùng');
    }
  }

  // 2. Tạo tài khoản Admin mới
  Future<User> createAdmin({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final Map<String, dynamic> requestBody = {
      'fullName': fullName,
      'email': email,
      'phone': phone ?? "",
      'password': password,
    };

    final response = await ApiService.post(
      'UserManagement/admin',
      body: requestBody,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return User.fromJson(json.decode(response.body));
    } else {
      print("Chi tiết lỗi từ server: ${response.body}");
      
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Dữ liệu không hợp lệ hoặc lỗi Server');
      } catch (e) {
        throw Exception('Lỗi tạo tài khoản admin (Status: ${response.statusCode})');
      }
    }
  }

  // 3. Khóa/Mở tài khoản - SỬA ĐÚNG STATUS THEO BACKEND
  Future<User> updateUserStatus(String userId, String status) async {
    // Backend chỉ chấp nhận: 'active', 'inactive', 'banned'
    final response = await ApiService.patch(
      'UserManagement/$userId/status',
      body: {'status': status},
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      print("Lỗi status: ${response.body}");
      throw Exception('Lỗi cập nhật trạng thái người dùng');
    }
  }
}
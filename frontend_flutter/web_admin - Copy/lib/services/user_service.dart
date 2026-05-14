import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';

class UserService {
  // 1. Lấy danh sách + Tìm kiếm + Lọc theo Role
  Future<List<User>> getUsers({String? keyword, String? role}) async {
    String endpoint = 'UserManagement/all';
    
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

  // 2. Tạo tài khoản Admin mới (Đã sửa để bắt message lỗi chi tiết)
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
      // Lấy chính xác câu "Email đã được sử dụng" từ backend trả về
      String serverMessage = 'Lỗi không xác định';
      try {
        final errorData = json.decode(response.body);
        serverMessage = errorData['message'] ?? 'Dữ liệu không hợp lệ';
      } catch (e) {
        serverMessage = 'Lỗi hệ thống (${response.statusCode})';
      }
      throw Exception(serverMessage); 
    }
  }

  // 3. Cập nhật trạng thái
  Future<User> updateUserStatus(String userId, String status) async {
    final response = await ApiService.patch(
      'UserManagement/$userId/status',
      body: {'status': status},
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Lỗi cập nhật trạng thái người dùng');
    }
  }
}
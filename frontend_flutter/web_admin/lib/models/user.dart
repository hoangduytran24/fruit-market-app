class User {
  final String userId;
  final String fullName;
  final String? phone;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;
  final String? token; // Thêm trường này để lưu JWT Token

  User({
    required this.userId,
    required this.fullName,
    this.phone,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    this.token, // Không bắt buộc vì khi lấy danh sách user sẽ không có token
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      token: json['token'], // Lấy token từ response login
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'status': status,
      'token': token,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
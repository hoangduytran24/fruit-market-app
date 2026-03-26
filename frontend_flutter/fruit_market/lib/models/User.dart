// class User {
//   final String userId;
//   final String fullName;
//   final String? phone;
//   final String? email;
//   final String passwordHash;
//   final String role;
//   final String status;
//   final DateTime createdAt;

//   User({
//     required this.userId,
//     required this.fullName,
//     this.phone,
//     this.email,
//     required this.passwordHash,
//     required this.role,
//     required this.status,
//     required this.createdAt,
//   });

//   /// JSON -> Object
//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       userId: json['userId'],
//       fullName: json['fullName'],
//       phone: json['phone'],
//       email: json['email'],
//       passwordHash: json['passwordHash'],
//       role: json['role'],
//       status: json['status'],
//       createdAt: DateTime.parse(json['createdAt']),
//     );
//   }

//   /// Object -> JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'userId': userId,
//       'fullName': fullName,
//       'phone': phone,
//       'email': email,
//       'passwordHash': passwordHash,
//       'role': role,
//       'status': status,
//       'createdAt': createdAt.toIso8601String(),
//     };
//   }
// }

class User {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? token;

  User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'token': token,
    };
  }
}
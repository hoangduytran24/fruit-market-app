class SupplierModel {
  final String supplierId;
  final String supplierName;
  final String? address;
  final String? phone;
  final String? email;
  final String? imageUrl;
  final String? status;
  final DateTime? createdAt;
  final int productCount;
  final bool isActive;

  SupplierModel({
    required this.supplierId,
    required this.supplierName,
    this.address,
    this.phone,
    this.email,
    this.imageUrl,
    this.status,
    this.createdAt,
    this.productCount = 0,
    this.isActive = true,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      imageUrl: json['imageUrl'],
      status: json['status'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      productCount: json['productCount'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'address': address,
      'phone': phone,
      'email': email,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'productCount': productCount,
      'isActive': isActive,
    };
  }
}
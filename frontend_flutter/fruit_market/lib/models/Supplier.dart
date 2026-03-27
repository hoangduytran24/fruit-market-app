import 'product.dart';

class Supplier {
  final String supplierId;
  final String supplierName;
  final String? phone;
  final String? address;
  final String status;
  final DateTime createdAt;

  final List<Product>? products;

  Supplier({
    required this.supplierId,
    required this.supplierName,
    this.phone,
    this.address,
    required this.status,
    required this.createdAt,
    this.products,
  });

  /// JSON -> Object
  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      phone: json['phone'],
      address: json['address'],
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      products: json['products'] != null
          ? (json['products'] as List)
              .map((e) => Product.fromJson(e))
              .toList()
          : null,
    );
  }

  /// Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'phone': phone,
      'address': address,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'products': products?.map((e) => e.toJson()).toList(),
    };
  }
}
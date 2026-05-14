// lib/models/inventory.dart

class Inventory {
  final String inventoryId;
  final String productId;
  final String productName;
  final String? productImage;
  final String batchCode;
  final int quantity;
  final DateTime? manufactureDate;
  final DateTime expiryDate;
  final double? importPrice;
  final DateTime importDate;
  final String status;
  final String statusText;
  final bool isExpired;
  final int daysToExpiry;
  final DateTime createdAt;

  Inventory({
    required this.inventoryId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.batchCode,
    required this.quantity,
    this.manufactureDate,
    required this.expiryDate,
    this.importPrice,
    required this.importDate,
    required this.status,
    required this.statusText,
    required this.isExpired,
    required this.daysToExpiry,
    required this.createdAt,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      inventoryId: json['inventoryId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'],
      batchCode: json['batchCode'] ?? '',
      quantity: json['quantity'] ?? 0,
      manufactureDate: json['manufactureDate'] != null 
          ? DateTime.parse(json['manufactureDate']) 
          : null,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate']) 
          : DateTime.now(),
      importPrice: json['importPrice']?.toDouble(),
      importDate: json['importDate'] != null 
          ? DateTime.parse(json['importDate']) 
          : DateTime.now(),
      status: json['status'] ?? 'in_stock',
      statusText: json['statusText'] ?? 'Còn hàng',
      isExpired: json['isExpired'] ?? false,
      daysToExpiry: json['daysToExpiry'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  // Helper properties
  bool get isInStock => status == 'in_stock' && !isExpired && quantity > 0;
  bool get isExpiringSoon => daysToExpiry > 0 && daysToExpiry <= 7;
  String get expiryStatus {
    if (isExpired) return 'Hết hạn';
    if (isExpiringSoon) return 'Sắp hết hạn';
    return 'Còn hạn';
  }
}

// DTO cho danh sách lô hàng (kiểu OrderListDto)
class InventoryListDto {
  final String inventoryId;
  final String productId;
  final String productName;
  final String? productImage;
  final String batchCode;
  final int quantity;
  final DateTime? manufactureDate;
  final DateTime expiryDate;
  final double? importPrice;
  final DateTime importDate;
  final String status;
  final String statusText;
  final bool isExpired;
  final int daysToExpiry;

  InventoryListDto({
    required this.inventoryId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.batchCode,
    required this.quantity,
    this.manufactureDate,
    required this.expiryDate,
    this.importPrice,
    required this.importDate,
    required this.status,
    required this.statusText,
    required this.isExpired,
    required this.daysToExpiry,
  });

  factory InventoryListDto.fromJson(Map<String, dynamic> json) {
    return InventoryListDto(
      inventoryId: json['inventoryId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'],
      batchCode: json['batchCode'] ?? '',
      quantity: json['quantity'] ?? 0,
      manufactureDate: json['manufactureDate'] != null 
          ? DateTime.parse(json['manufactureDate']) 
          : null,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate']) 
          : DateTime.now(),
      importPrice: json['importPrice']?.toDouble(),
      importDate: json['importDate'] != null 
          ? DateTime.parse(json['importDate']) 
          : DateTime.now(),
      status: json['status'] ?? 'in_stock',
      statusText: json['statusText'] ?? 'Còn hàng',
      isExpired: json['isExpired'] ?? false,
      daysToExpiry: json['daysToExpiry'] ?? 0,
    );
  }
}
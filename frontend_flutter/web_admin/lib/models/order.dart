class Order {
  final String orderId;
  final String userId;
  final String customerName;
  final String? customerPhone;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryAddress;
  final DateTime createdAt;
  final String? voucherCode;
  final List<OrderItem> items;

  Order({
    required this.orderId,
    required this.userId,
    required this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.createdAt,
    this.voucherCode,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      customerName: json['customerName'] ?? 'Khách hàng',
      customerPhone: json['customerPhone'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'COD',
      paymentStatus: json['paymentStatus'] ?? 'Unpaid',
      deliveryAddress: json['deliveryAddress'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      voucherCode: json['voucherCode'],
      items: (json['items'] as List?)
          ?.map((e) => OrderItem.fromJson(e))
          .toList() ?? [],
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String? imageUrl;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItem({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] ?? '',
      imageUrl: json['imageUrl'],
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

class OrderListDto {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final DateTime createdAt;
  final double finalAmount;
  final String status;
  final int itemCount;
  final String paymentStatus; // 1. THÊM DÒNG NÀY

  OrderListDto({
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.createdAt,
    required this.finalAmount,
    required this.status,
    required this.itemCount,
    required this.paymentStatus, // 2. THÊM DÒNG NÀY
  });

  factory OrderListDto.fromJson(Map<String, dynamic> json) {
    return OrderListDto(
      orderId: json['orderId']?.toString() ?? '',
      customerName: json['customerName'] ?? 'Khách hàng',
      customerPhone: json['customerPhone'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      itemCount: json['itemCount'] ?? 0,
      // 3. THÊM DÒNG NÀY (Đảm bảo khớp key với API trả về)
      paymentStatus: json['paymentStatus'] ?? 'unpaid', 
    );
  }
}
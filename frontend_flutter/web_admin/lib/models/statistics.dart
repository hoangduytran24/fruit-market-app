class DashboardStats {
  final int totalOrders;
  final int totalUsers;
  final int totalProducts;
  final double totalRevenue;
  final double todayRevenue;
  final int todayOrders;
  final int pendingOrders;
  final int lowStockProducts;

  DashboardStats({
    required this.totalOrders,
    required this.totalUsers,
    required this.totalProducts,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.todayOrders,
    required this.pendingOrders,
    required this.lowStockProducts,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalOrders: json['totalOrders'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      todayOrders: json['todayOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      lowStockProducts: json['lowStockProducts'] ?? 0,
    );
  }
}

class TopProduct {
  final String productId;
  final String productName;
  final int totalQuantitySold;
  final double totalRevenue;
  final String imageUrl;

  TopProduct({
    required this.productId,
    required this.productName,
    required this.totalQuantitySold,
    required this.totalRevenue,
    required this.imageUrl,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      totalQuantitySold: json['totalQuantitySold'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}

class RevenueData {
  final DateTime date;
  final double revenue;
  final int orderCount;

  RevenueData({required this.date, required this.revenue, required this.orderCount});

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      date: DateTime.parse(json['date']),
      revenue: (json['revenue'] ?? 0).toDouble(),
      orderCount: json['orderCount'] ?? 0,
    );
  }
}

class OrderStatusStats {
  final int pending;
  final int processing;
  final int shipping;
  final int completed;
  final int cancelled;

  OrderStatusStats({
    required this.pending,
    required this.processing,
    required this.shipping,
    required this.completed,
    required this.cancelled,
  });

  factory OrderStatusStats.fromJson(Map<String, dynamic> json) {
    return OrderStatusStats(
      pending: json['pending'] ?? 0,
      processing: json['processing'] ?? 0,
      shipping: json['shipping'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
    );
  }
}

class UserStats {
  final int total;
  final int active;
  final int inactive;
  final int banned;
  final int customers;
  final int admins;

  UserStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.banned,
    required this.customers,
    required this.admins,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      inactive: json['inactive'] ?? 0,
      banned: json['banned'] ?? 0,
      customers: json['customers'] ?? 0,
      admins: json['admins'] ?? 0,
    );
  }
}
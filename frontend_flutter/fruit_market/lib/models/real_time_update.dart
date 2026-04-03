class RealTimeUpdate {
  final String eventType;
  final String message;
  final dynamic data;
  final String? userId;
  final DateTime timestamp;

  RealTimeUpdate({
    required this.eventType,
    required this.message,
    this.data,
    this.userId,
    required this.timestamp,
  });

  factory RealTimeUpdate.fromJson(Map<String, dynamic> json) {
    return RealTimeUpdate(
      eventType: json['eventType'] ?? '',
      message: json['message'] ?? '',
      data: json['data'],
      userId: json['userId'],
      // Chuyển đổi timestamp từ chuỗi ISO 8601 của .NET sang DateTime của Dart
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}
class ReturnRequest {
  final String returnId;
  final String orderId;
  final String userId;
  final String reason;
  final String? description;
  final String? imageUrl;
  final String status;
  final double refundAmount;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;
  final DateTime? rejectedAt;
  final String? rejectReason;
  final String statusText;

  ReturnRequest({
    required this.returnId,
    required this.orderId,
    required this.userId,
    required this.reason,
    this.description,
    this.imageUrl,
    required this.status,
    required this.refundAmount,
    required this.createdAt,
    this.approvedAt,
    this.completedAt,
    this.rejectedAt,
    this.rejectReason,
    required this.statusText,
  });

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      returnId: json['returnId'] ?? '',
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'pending',
      refundAmount: (json['refundAmount'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'])
          : null,
      rejectReason: json['rejectReason'],
      statusText: json['statusText'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'returnId': returnId,
      'orderId': orderId,
      'userId': userId,
      'reason': reason,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'refundAmount': refundAmount,
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectReason': rejectReason,
      'statusText': statusText,
    };
  }
}
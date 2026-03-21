class BuyNowRequest {
  final String productId;
  final int quantity;
  final String paymentMethod;
  final String deliveryAddress;
  final String? voucherCode;

  BuyNowRequest({
    required this.productId,
    required this.quantity,
    required this.paymentMethod,
    required this.deliveryAddress,
    this.voucherCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress,
      'voucherCode': voucherCode,
    };
  }
}
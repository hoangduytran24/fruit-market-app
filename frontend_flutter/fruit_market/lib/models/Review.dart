import 'user.dart';
import 'product.dart';

class Review {
  final String reviewId;
  final String userId;
  final String productId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  final User? user;
  final Product? product;

  Review({
    required this.reviewId,
    required this.userId,
    required this.productId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.user,
    this.product,
  });

  /// JSON -> Object
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['reviewId'],
      userId: json['userId'],
      productId: json['productId'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }

  /// Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'userId': userId,
      'productId': productId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'user': user?.toJson(),
      'product': product?.toJson(),
    };
  }
}
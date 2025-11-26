// lib/models/review.dart
class Review {
  final int id;
  final int userId;
  final int productId;
  final int orderId;
  final int rating;
  final String? comment;
  final String createdAt;
  final String? userName;

  Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.orderId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.userName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      orderId: json['order_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: json['created_at'],
      userName: json['user_name'],
    );
  }
}

// lib/services/review_service.dart
import '../config/api_config.dart';
import '../models/review.dart';
import 'api_service.dart';

class ReviewService {
  // Get product reviews
  static Future<Map<String, dynamic>> getProductReviews({
    required int productId,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = {'page': page.toString(), 'limit': limit.toString()};

    final response = await ApiService.get(
      '${ApiConfig.reviews}/product/$productId',
      queryParams: queryParams,
    );

    final List<dynamic> reviewsJson = response['reviews'];
    final reviews = reviewsJson.map((json) => Review.fromJson(json)).toList();

    return {'reviews': reviews, 'pagination': response['pagination']};
  }

  // Create review
  static Future<void> createReview({
    required int productId,
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    await ApiService.post(
      '${ApiConfig.reviews}/create',
      body: {
        'product_id': productId,
        'order_id': orderId,
        'rating': rating,
        'comment': comment,
      },
      needsAuth: true,
    );
  }

  // Update review
  static Future<void> updateReview({
    required int reviewId,
    int? rating,
    String? comment,
  }) async {
    await ApiService.put(
      '${ApiConfig.reviews}/$reviewId',
      body: {'rating': rating, 'comment': comment},
      needsAuth: true,
    );
  }

  // Delete review
  static Future<void> deleteReview(int reviewId) async {
    await ApiService.delete('${ApiConfig.reviews}/$reviewId', needsAuth: true);
  }
}

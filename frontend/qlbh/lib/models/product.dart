// lib/models/product.dart
import '../config/api_config.dart';

class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final int? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final bool hasImage;
  final double? averageRating;
  final int? totalReviews;
  final List<String>? images;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.hasImage = false,
    this.averageRating,
    this.totalReviews,
    this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      stockQuantity: json['stock_quantity'] ?? 0,
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      imageUrl: json['image_url'],
      hasImage: json['has_image'] ?? false,
      averageRating: json['average_rating'] != null
          ? double.parse(json['average_rating'].toString())
          : null,
      totalReviews: json['total_reviews'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  // ✅ QUAN TRỌNG: Helper để lấy full URL ảnh
  String? get fullImageUrl {
    if (!hasImage || imageUrl == null || imageUrl!.isEmpty) {
      return null;
    }

    // Nếu imageUrl đã là full URL (http/https)
    if (imageUrl!.startsWith('http')) {
      return imageUrl;
    }

    // Nếu imageUrl là relative path như "/products/1/image"
    // Cần ghép với ApiConfig.baseUrl
    // ApiConfig.baseUrl = "http://127.0.0.1:5000/api"
    // imageUrl = "/products/1/image"
    // Result = "http://127.0.0.1:5000/api/products/1/image"
    return '${ApiConfig.baseUrl}$imageUrl';
  }

  String get displayImage {
    final fullUrl = fullImageUrl;
    if (fullUrl != null && fullUrl.isNotEmpty) {
      return fullUrl;
    }
    if (images != null && images!.isNotEmpty) {
      return images!.first;
    }
    return '';
  }
}

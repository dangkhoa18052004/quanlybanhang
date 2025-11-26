// lib/models/product.dart
class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final int? categoryId;
  final String? categoryName;
  final String? imageUrl;
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
      averageRating: json['average_rating'] != null
          ? double.parse(json['average_rating'].toString())
          : null,
      totalReviews: json['total_reviews'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  String get displayImage {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    if (images != null && images!.isNotEmpty) {
      return images!.first;
    }
    return '';
  }
}

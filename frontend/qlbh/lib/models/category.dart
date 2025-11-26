// lib/models/category.dart
class Category {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int? productCount;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.productCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      productCount: json['product_count'],
    );
  }
}

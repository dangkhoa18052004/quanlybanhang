// lib/widgets/product_image.dart
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductImage extends StatelessWidget {
  final Product product;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProductImage({
    Key? key,
    required this.product,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.fullImageUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey[600],
        ),
      );
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Image load error: $error');
        print('❌ Image URL: $imageUrl');
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.red),
              SizedBox(height: 4),
              Text(
                'Lỗi tải ảnh',
                style: TextStyle(fontSize: 10, color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }
}

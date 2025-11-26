// lib/screens/home/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qlbh/screens/cart/cart_screen.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/theme_config.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({Key? key, required this.productId})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final provider = context.read<ProductProvider>();
    await provider.loadProductDetail(widget.productId);
  }

  Future<void> _addToCart() async {
    final product = context.read<ProductProvider>().selectedProduct;
    if (product == null) return;

    if (product.stockQuantity < _quantity) {
      Fluttertoast.showToast(
        msg: 'Số lượng vượt quá tồn kho',
        backgroundColor: Colors.red,
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final success = await cartProvider.addToCart(
      product.id,
      quantity: _quantity,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: 'Đã thêm vào giỏ hàng',
        backgroundColor: AppTheme.successColor,
      );
    } else {
      Fluttertoast.showToast(
        msg: cartProvider.error ?? 'Thêm vào giỏ hàng thất bại',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return IconButton(
                icon: Badge(
                  label: Text('${cart.itemCount}'),
                  isLabelVisible: cart.itemCount > 0,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProduct,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final product = provider.selectedProduct;
          if (product == null) {
            return const Center(child: Text('Không tìm thấy sản phẩm'));
          }

          final images = product.images ?? [product.displayImage];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Images
                      SizedBox(
                        height: 300,
                        child: Stack(
                          children: [
                            PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final imageUrl = images[index];
                                return Container(
                                  color: Colors.grey[100],
                                  child: imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl:
                                              'http://192.168.1.100:5000$imageUrl',
                                          fit: BoxFit.contain,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                                Icons.image_not_supported,
                                                size: 100,
                                              ),
                                        )
                                      : const Icon(Icons.image, size: 100),
                                );
                              },
                            ),
                            // Image indicator
                            if (images.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    images.length,
                                    (index) => Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentImageIndex == index
                                            ? AppTheme.primaryColor
                                            : Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Product Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price
                            Text(
                              Helpers.formatCurrency(product.price),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Product Name
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Rating & Reviews
                            if (product.averageRating != null &&
                                product.averageRating! > 0)
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: product.averageRating!,
                                    itemBuilder: (context, index) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    itemCount: 5,
                                    itemSize: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${product.averageRating!.toStringAsFixed(1)} (${product.totalReviews ?? 0} đánh giá)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),

                            // Stock Status
                            Row(
                              children: [
                                const Text(
                                  'Tình trạng: ',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  product.stockQuantity > 0
                                      ? 'Còn hàng (${product.stockQuantity})'
                                      : 'Hết hàng',
                                  style: TextStyle(
                                    color: product.stockQuantity > 0
                                        ? AppTheme.successColor
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Category
                            if (product.categoryName != null)
                              Row(
                                children: [
                                  const Text(
                                    'Danh mục: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(product.categoryName!),
                                    backgroundColor: AppTheme.primaryColor
                                        .withOpacity(0.1),
                                    labelStyle: const TextStyle(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),

                            const Divider(),
                            const SizedBox(height: 16),

                            // Description
                            const Text(
                              'Mô tả sản phẩm',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.description ?? 'Không có mô tả',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 100), // Space for bottom bar
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Bar (Quantity & Add to Cart)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Quantity selector
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _quantity > 1
                                  ? () {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _quantity < product.stockQuantity
                                  ? () {
                                      setState(() {
                                        _quantity++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Add to Cart Button
                      Expanded(
                        child: CustomButton(
                          text: 'Thêm vào giỏ',
                          onPressed: product.stockQuantity > 0
                              ? _addToCart
                              : () {},
                          icon: Icons.shopping_cart,
                          isLoading: context.watch<CartProvider>().isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

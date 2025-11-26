// lib/screens/reviews/product_reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../services/review_service.dart';
import '../../models/review.dart';
import '../../config/theme_config.dart';
import '../../utils/helpers.dart';

class ProductReviewsScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const ProductReviewsScreen({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadReviews();
      }
    }
  }

  Future<void> _loadReviews({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _reviews.clear();
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ReviewService.getProductReviews(
        productId: widget.productId,
        page: _currentPage,
      );

      final List<Review> newReviews = result['reviews'];
      final pagination = result['pagination'];

      setState(() {
        if (refresh) {
          _reviews = newReviews;
        } else {
          _reviews.addAll(newReviews);
        }
        _currentPage++;
        _hasMore = _currentPage <= pagination['total_pages'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá sản phẩm')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadReviews(refresh: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đánh giá',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadReviews(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _reviews.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final review = _reviews[index];
          return _buildReviewCard(review);
        },
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info & rating
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    review.userName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName ?? 'Người dùng',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: review.rating.toDouble(),
                            itemBuilder: (context, index) =>
                                const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Helpers.formatDateShort(review.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Comment
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

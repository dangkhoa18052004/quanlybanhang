// lib/screens/reviews/write_review_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/review_service.dart';
import '../../config/theme_config.dart';
import '../../widgets/custom_button.dart';

class WriteReviewScreen extends StatefulWidget {
  final int productId;
  final int orderId;
  final String productName;

  const WriteReviewScreen({
    Key? key,
    required this.productId,
    required this.orderId,
    required this.productName,
  }) : super(key: key);

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      Fluttertoast.showToast(
        msg: 'Vui lòng chọn số sao đánh giá',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ReviewService.createReview(
        productId: widget.productId,
        orderId: widget.orderId,
        rating: _rating.toInt(),
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;

      Fluttertoast.showToast(
        msg: 'Đánh giá thành công',
        backgroundColor: AppTheme.successColor,
      );
      Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString(), backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getRatingText() {
    switch (_rating.toInt()) {
      case 1:
        return 'Rất tệ';
      case 2:
        return 'Tệ';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Tốt';
      case 5:
        return 'Rất tốt';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá sản phẩm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rating Section
            Center(
              child: Column(
                children: [
                  const Text(
                    'Bạn cảm thấy sản phẩm thế nào?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 50,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getRatingText(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Comment Section
            const Text(
              'Chia sẻ thêm về sản phẩm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Mô tả trải nghiệm của bạn về sản phẩm (tùy chọn)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            CustomButton(
              text: 'Gửi đánh giá',
              onPressed: _submitReview,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

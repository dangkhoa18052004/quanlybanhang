// lib/screens/orders/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/order_provider.dart';
import '../../config/theme_config.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../reviews/write_review_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    final orderProvider = context.read<OrderProvider>();
    await orderProvider.loadOrderDetail(widget.orderId);
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final orderProvider = context.read<OrderProvider>();
      final success = await orderProvider.cancelOrder(widget.orderId);

      if (success) {
        Fluttertoast.showToast(
          msg: 'Đã hủy đơn hàng',
          backgroundColor: AppTheme.successColor,
        );
        _loadOrderDetail();
      } else {
        Fluttertoast.showToast(
          msg: orderProvider.error ?? 'Hủy đơn hàng thất bại',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: Consumer<OrderProvider>(
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
                    onPressed: _loadOrderDetail,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final order = provider.selectedOrder;
          if (order == null) {
            return const Center(child: Text('Không tìm thấy đơn hàng'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.orderNumber,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    onPressed: () {
                                      // Copy order number
                                      Fluttertoast.showToast(
                                        msg: 'Đã sao chép mã đơn hàng',
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Đặt ngày: ${Helpers.formatDate(order.createdAt)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Timeline
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Trạng thái đơn hàng',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildStatusTimeline(order.status),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text('Thanh toán: '),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: order.paymentStatus == 'paid'
                                          ? AppTheme.successColor.withOpacity(
                                              0.1,
                                            )
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      Helpers.getPaymentStatusText(
                                        order.paymentStatus,
                                      ),
                                      style: TextStyle(
                                        color: order.paymentStatus == 'paid'
                                            ? AppTheme.successColor
                                            : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Shipping Info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin giao hàng',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.phone,
                                'Số điện thoại',
                                order.phone,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.location_on,
                                'Địa chỉ',
                                order.shippingAddress,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.payment,
                                'Phương thức',
                                order.paymentMethod == 'momo' ? 'MoMo' : 'COD',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Order Items
                      const Text(
                        'Sản phẩm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...?order.items?.map((item) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Product Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey[200],
                                    child: item.productImage != null
                                        ? CachedNetworkImage(
                                            imageUrl:
                                                'http://10.0.2.2:5000${item.productImage}',
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.image),
                                          )
                                        : const Icon(Icons.image),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Product Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'x${item.quantity}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Helpers.formatCurrency(item.price),
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Price
                                Text(
                                  Helpers.formatCurrency(item.subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),

                      // Payment Summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildSummaryRow(
                                'Tạm tính:',
                                Helpers.formatCurrency(order.subtotal),
                              ),
                              const SizedBox(height: 8),
                              if (order.discountAmount > 0) ...[
                                _buildSummaryRow(
                                  'Giảm giá (${order.discountCode ?? ""}):',
                                  '-${Helpers.formatCurrency(order.discountAmount)}',
                                  color: AppTheme.successColor,
                                ),
                                const SizedBox(height: 8),
                              ],
                              _buildSummaryRow(
                                'Phí vận chuyển:',
                                'Miễn phí',
                                color: AppTheme.successColor,
                              ),
                              const Divider(height: 24),
                              _buildSummaryRow(
                                'Tổng cộng:',
                                Helpers.formatCurrency(order.totalAmount),
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cancel Button (only for pending orders)
                      if (order.status == 'pending' &&
                          order.paymentStatus != 'paid')
                        CustomButton(
                          text: 'Hủy đơn hàng',
                          onPressed: _cancelOrder,
                          isOutlined: true,
                          color: Colors.red,
                        ),

                      // Review Button (only for delivered orders)
                      if (order.status == 'delivered')
                        CustomButton(
                          text: 'Đánh giá sản phẩm',
                          onPressed: () {
                            // Navigate to review screen for first item
                            if (order.items != null &&
                                order.items!.isNotEmpty) {
                              final firstItem = order.items!.first;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WriteReviewScreen(
                                    productId: firstItem.productId,
                                    orderId: order.id,
                                    productName: firstItem.productName,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: Icons.rate_review,
                        ),

                      // Contact Support Button
                      if (order.status != 'cancelled')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Fluttertoast.showToast(
                                msg: 'Chức năng đang phát triển',
                              );
                            },
                            icon: const Icon(Icons.headset_mic),
                            label: const Text('Liên hệ hỗ trợ'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
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

  Widget _buildStatusTimeline(String currentStatus) {
    final statuses = [
      {'key': 'pending', 'label': 'Chờ xác nhận', 'icon': Icons.schedule},
      {'key': 'confirmed', 'label': 'Đã xác nhận', 'icon': Icons.check_circle},
      {'key': 'shipping', 'label': 'Đang giao', 'icon': Icons.local_shipping},
      {'key': 'delivered', 'label': 'Đã giao', 'icon': Icons.done_all},
    ];

    int currentIndex = statuses.indexWhere((s) => s['key'] == currentStatus);
    if (currentStatus == 'cancelled') currentIndex = -1;

    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.primaryColor
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status['icon'] as IconData,
                    color: isCompleted ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted
                        ? AppTheme.primaryColor
                        : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  status['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted
                        ? AppTheme.textPrimaryColor
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isTotal ? AppTheme.primaryColor : null),
          ),
        ),
      ],
    );
  }
}

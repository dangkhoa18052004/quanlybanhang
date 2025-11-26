// lib/screens/cart/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/payment_service.dart';
import '../../config/theme_config.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../orders/order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _discountCodeController = TextEditingController();

  String _paymentMethod = 'momo';
  bool _isProcessing = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _discountCodeController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Create order
      final response = await PaymentService.createOrder(
        shippingAddress: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        discountCode: _discountCodeController.text.trim().isNotEmpty
            ? _discountCodeController.text.trim()
            : null,
        paymentMethod: _paymentMethod,
      );

      final orderId = response['order']['id'];
      final paymentCode = response['payment']['payment_code'];

      if (_paymentMethod == 'momo') {
        // 2. Initiate MoMo payment
        final momoResponse = await PaymentService.initiateMoMoPayment(
          paymentCode: paymentCode,
        );

        final paymentUrl = momoResponse['payment_url'];

        if (!mounted) return;

        // 3. Open MoMo WebView
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MoMoPaymentWebView(
              paymentUrl: paymentUrl,
              paymentCode: paymentCode,
            ),
          ),
        );

        if (result == true) {
          // Payment successful
          if (!mounted) return;

          // Clear cart
          await context.read<CartProvider>().clearCart();

          // Navigate to order detail
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: orderId),
            ),
            (route) => route.isFirst,
          );
        }
      } else {
        // COD payment
        if (!mounted) return;

        await context.read<CartProvider>().clearCart();

        Fluttertoast.showToast(
          msg: 'Đặt hàng thành công!',
          backgroundColor: AppTheme.successColor,
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: orderId),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString(), backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shipping Info
                    const Text(
                      'Thông tin giao hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại *',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        if (!RegExp(r'^0[0-9]{9}$').hasMatch(value)) {
                          return 'Số điện thoại không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ giao hàng *',
                        prefixIcon: Icon(Icons.location_on),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập địa chỉ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Payment Method
                    const Text(
                      'Phương thức thanh toán',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildPaymentMethodTile(
                      value: 'momo',
                      title: 'MoMo',
                      subtitle: 'Thanh toán qua ví MoMo',
                      icon: Icons.payment,
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentMethodTile(
                      value: 'cod',
                      title: 'Thanh toán khi nhận hàng (COD)',
                      subtitle: 'Thanh toán bằng tiền mặt khi nhận hàng',
                      icon: Icons.money,
                    ),
                    const SizedBox(height: 24),

                    // Discount Code
                    const Text(
                      'Mã giảm giá',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Nhập mã giảm giá',
                              prefixIcon: Icon(Icons.discount),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Apply discount code
                            Fluttertoast.showToast(
                              msg: 'Chức năng đang phát triển',
                            );
                          },
                          child: const Text('Áp dụng'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Order Summary
                    const Text(
                      'Tóm tắt đơn hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              'Tạm tính:',
                              Helpers.formatCurrency(cart.total),
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Phí vận chuyển:', 'Miễn phí'),
                            const Divider(height: 24),
                            _buildSummaryRow(
                              'Tổng cộng:',
                              Helpers.formatCurrency(cart.total),
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

            // Bottom Bar
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
                child: CustomButton(
                  text: 'Đặt hàng',
                  onPressed: _processOrder,
                  isLoading: _isProcessing,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      child: RadioListTile<String>(
        value: value,
        groupValue: _paymentMethod,
        onChanged: (val) {
          setState(() {
            _paymentMethod = val!;
          });
        },
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 36, top: 4),
          child: Text(subtitle),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppTheme.primaryColor : null,
          ),
        ),
      ],
    );
  }
}

// MoMo WebView
class MoMoPaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String paymentCode;

  const MoMoPaymentWebView({
    Key? key,
    required this.paymentUrl,
    required this.paymentCode,
  }) : super(key: key);

  @override
  State<MoMoPaymentWebView> createState() => _MoMoPaymentWebViewState();
}

class _MoMoPaymentWebViewState extends State<MoMoPaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('[WEBVIEW] Page started: $url');

            // Check if payment completed
            if (url.contains('payment/success')) {
              Navigator.pop(context, true);
            } else if (url.contains('payment/failed')) {
              Navigator.pop(context, false);
            }
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán MoMo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

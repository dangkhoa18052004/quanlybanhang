// lib/screens/cart/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/cart_provider.dart';
import '../../services/payment_service.dart';
import '../../services/discount_service.dart';
import '../../config/theme_config.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../orders/order_detail_screen.dart';
import '../discount/discount_codes_screen.dart';
import '../payment/momo_qr_screen.dart';

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
  bool _isApplyingDiscount = false;

  // Discount state
  String? _appliedDiscountCode;
  double _discountAmount = 0;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _discountCodeController.dispose();
    super.dispose();
  }

  /// Apply discount code
  Future<void> _applyDiscountCode() async {
    final code = _discountCodeController.text.trim();
    if (code.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Vui lòng nhập mã giảm giá',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isApplyingDiscount = true);

    try {
      final cart = context.read<CartProvider>();
      final response = await DiscountService.validateCode(
        code: code,
        orderTotal: cart.total,
      );

      if (response['valid'] == true) {
        setState(() {
          _appliedDiscountCode = code;
          _discountAmount = (response['discount']['discount_amount'] as num)
              .toDouble();
        });

        Fluttertoast.showToast(
          msg:
              'Áp dụng mã thành công! Giảm ${Helpers.formatCurrency(_discountAmount)}',
          backgroundColor: AppTheme.successColor,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      print('[DISCOUNT ERROR] $e');
      Fluttertoast.showToast(
        msg: e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isApplyingDiscount = false);
    }
  }

  /// Remove discount code
  void _removeDiscountCode() {
    setState(() {
      _appliedDiscountCode = null;
      _discountAmount = 0;
      _discountCodeController.clear();
    });
    Fluttertoast.showToast(
      msg: 'Đã xóa mã giảm giá',
      backgroundColor: Colors.grey,
    );
  }

  /// Show discount codes screen
  void _showDiscountCodes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiscountCodesScreen(
          onCodeSelected: (code) {
            _discountCodeController.text = code;
            _applyDiscountCode();
          },
        ),
      ),
    );
  }

  /// Process order
  Future<void> _processOrder() async {
    // Prevent multiple clicks
    if (_isProcessing) {
      print('[CHECKOUT] Already processing, ignoring click');
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Check cart not empty
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Giỏ hàng trống!',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      print('[CHECKOUT] Creating order...');

      // 1. Create order
      final response = await PaymentService.createOrder(
        shippingAddress: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        discountCode: _appliedDiscountCode,
        paymentMethod: _paymentMethod,
      );

      print('[CHECKOUT] Order created: ${response['order']['order_number']}');

      final orderId = response['order']['id'];
      final orderNumber = response['order']['order_number'];
      final paymentCode = response['payment']['payment_code'];
      final finalTotal = cart.total - _discountAmount;

      if (_paymentMethod == 'momo') {
        print('[CHECKOUT] Initiating MoMo payment...');

        // 2. Initiate MoMo payment
        final momoResponse = await PaymentService.initiateMoMoQR(
          paymentCode: paymentCode,
        );

        print('[CHECKOUT] MoMo Response: $momoResponse');

        final qrCodeImage = momoResponse['qr_code_image'];
        final deepLink = momoResponse['deep_link'];

        if (qrCodeImage == null) {
          throw Exception('Không nhận được mã QR từ MoMo');
        }

        if (!mounted) return;

        // 3. Show QR Screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MoMoQRScreen(
              qrCodeImage: qrCodeImage,
              deepLink: deepLink,
              orderNumber: orderNumber,
              amount: finalTotal,
              paymentCode: paymentCode,
            ),
          ),
        );

        if (!mounted) return;

        // 4. After user returns, check payment status
        print('[CHECKOUT] Checking payment status...');

        try {
          final statusResponse = await PaymentService.checkPaymentStatus(
            paymentCode,
          );

          print(
            '[CHECKOUT] Payment status: ${statusResponse['payment_status']}',
          );

          if (statusResponse['payment_status'] == 'completed') {
            // Payment successful
            print('[CHECKOUT] Payment verified as completed');

            await cart.clearCart();

            Fluttertoast.showToast(
              msg: 'Thanh toán thành công!\nMã đơn: $orderNumber',
              backgroundColor: AppTheme.successColor,
              toastLength: Toast.LENGTH_LONG,
            );

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: orderId),
              ),
              (route) => route.isFirst,
            );
          } else {
            // Payment pending or failed
            Fluttertoast.showToast(
              msg:
                  'Chưa nhận được xác nhận thanh toán.\nVui lòng kiểm tra lại đơn hàng.',
              backgroundColor: Colors.orange,
              toastLength: Toast.LENGTH_LONG,
            );

            // Navigate to order detail to let user check status
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: orderId),
              ),
              (route) => route.isFirst,
            );
          }
        } catch (e) {
          print('[CHECKOUT] Error checking status: $e');
          Fluttertoast.showToast(
            msg:
                'Không thể kiểm tra trạng thái thanh toán.\nVui lòng kiểm tra đơn hàng.',
            backgroundColor: Colors.orange,
            toastLength: Toast.LENGTH_LONG,
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: orderId),
            ),
            (route) => route.isFirst,
          );
        }
      } else {
        // COD payment
        print('[CHECKOUT] COD payment selected');

        if (!mounted) return;

        await cart.clearCart();

        Fluttertoast.showToast(
          msg: 'Đặt hàng thành công!\nMã đơn: $orderNumber',
          backgroundColor: AppTheme.successColor,
          toastLength: Toast.LENGTH_LONG,
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: orderId),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      print('[CHECKOUT ERROR] $e');

      // Better error messages
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.replaceAll('Exception: ', '');
      }
      if (errorMsg.contains('error')) {
        // Try to extract error from JSON response
        try {
          final match = RegExp(r'"error":\s*"([^"]+)"').firstMatch(errorMsg);
          if (match != null) {
            errorMsg = match.group(1)!;
          }
        } catch (_) {}
      }

      Fluttertoast.showToast(
        msg: errorMsg,
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final finalTotal = cart.total - _discountAmount;

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
                            decoration: InputDecoration(
                              labelText: 'Nhập mã giảm giá',
                              prefixIcon: const Icon(Icons.discount),
                              suffixIcon: _appliedDiscountCode != null
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.red,
                                      ),
                                      onPressed: _removeDiscountCode,
                                    )
                                  : null,
                            ),
                            enabled: _appliedDiscountCode == null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed:
                              _appliedDiscountCode == null &&
                                  !_isApplyingDiscount
                              ? _applyDiscountCode
                              : null,
                          child: _isApplyingDiscount
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Áp dụng'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.card_giftcard),
                          onPressed: _showDiscountCodes,
                          tooltip: 'Xem mã khả dụng',
                        ),
                      ],
                    ),

                    // Show applied discount info
                    if (_appliedDiscountCode != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.successColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.successColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đã áp dụng mã $_appliedDiscountCode - Giảm ${Helpers.formatCurrency(_discountAmount)}',
                                style: const TextStyle(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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

                            // Show discount if applied
                            if (_discountAmount > 0) ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Giảm giá:',
                                '-${Helpers.formatCurrency(_discountAmount)}',
                                textColor: AppTheme.successColor,
                              ),
                            ],

                            const Divider(height: 24),
                            _buildSummaryRow(
                              'Tổng cộng:',
                              Helpers.formatCurrency(finalTotal),
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
                  onPressed: _isProcessing ? null : _processOrder,
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
            Expanded(child: Text(title)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 36, top: 4),
          child: Text(subtitle),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? textColor,
  }) {
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
            color: textColor ?? (isTotal ? AppTheme.primaryColor : null),
          ),
        ),
      ],
    );
  }
}

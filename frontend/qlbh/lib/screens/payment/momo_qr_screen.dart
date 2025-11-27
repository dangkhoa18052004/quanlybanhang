import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme_config.dart';
import '../../utils/helpers.dart';

class MoMoQRScreen extends StatelessWidget {
  final String qrCodeImage; // base64 string
  final String? deepLink;
  final String orderNumber;
  final double amount;

  const MoMoQRScreen({
    Key? key,
    required this.qrCodeImage,
    this.deepLink,
    required this.orderNumber,
    required this.amount,
    required paymentCode,
  }) : super(key: key);

  Future<void> _openMoMoApp(BuildContext context) async {
    if (deepLink != null) {
      final uri = Uri.parse(deepLink!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng MoMo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán MoMo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Order Info
            Text(
              'Mã đơn: $orderNumber',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Helpers.formatCurrency(amount),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),

            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.memory(
                base64Decode(qrCodeImage.split(',').last),
                width: 280,
                height: 280,
              ),
            ),

            const SizedBox(height: 32),

            // Instructions
            const Text(
              'Quét mã QR bằng ứng dụng MoMo để thanh toán',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Open MoMo App Button
            if (deepLink != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openMoMoApp(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text(
                    'Mở ứng dụng MoMo',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sau khi thanh toán thành công, vui lòng quay lại màn hình này để kiểm tra trạng thái đơn hàng',
                      style: TextStyle(fontSize: 14, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

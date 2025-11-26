// lib/services/payment_service.dart
import '../config/api_config.dart';
import 'api_service.dart';

class PaymentService {
  // Create order and payment
  static Future<Map<String, dynamic>> createOrder({
    required String shippingAddress,
    required String phone,
    String? discountCode,
    String paymentMethod = 'momo',
  }) async {
    final response = await ApiService.post(
      '${ApiConfig.payment}/create-order',
      body: {
        'shipping_address': shippingAddress,
        'phone': phone,
        'discount_code': discountCode,
        'payment_method': paymentMethod,
      },
      needsAuth: true,
    );

    return response;
  }

  // Initiate MoMo payment
  static Future<Map<String, dynamic>> initiateMoMoPayment({
    required String paymentCode,
  }) async {
    final response = await ApiService.post(
      '${ApiConfig.payment}/initiate-momo',
      body: {'payment_code': paymentCode},
      needsAuth: true,
    );

    return response;
  }

  // Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus(
    String paymentCode,
  ) async {
    final response = await ApiService.get(
      '${ApiConfig.payment}/status/$paymentCode',
      needsAuth: true,
    );

    return response;
  }
}

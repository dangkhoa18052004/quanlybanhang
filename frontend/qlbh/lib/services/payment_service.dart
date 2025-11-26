// lib/services/payment_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class PaymentService {
  // Hàm trợ giúp lấy Token (Giả định bạn có hàm này)
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Thay 'auth_token' bằng key bạn dùng để lưu JWT
    return prefs.getString('auth_token');
  }

  // ----------------------------------------------------------------------
  // 1. HÀM KHỞI TẠO MOMO QR (FIX LỖI 'undefined_method')
  // ----------------------------------------------------------------------

  static Future<Map<String, dynamic>> initiateMoMoQR({
    required String paymentCode,
  }) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('Không có token xác thực');
    }

    try {
      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.payment}/initiate-momo-qr',
            ), // Endpoint Backend
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'payment_code': paymentCode}),
          )
          .timeout(ApiConfig.connectTimeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        final errorMessage =
            responseData['error'] ?? 'Lỗi khởi tạo thanh toán MoMo';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Lỗi kết nối hoặc xử lý dữ liệu: $e');
    }
  }

  // ----------------------------------------------------------------------
  // 2. HÀM TẠO ĐƠN HÀNG (Cần thiết cho checkout_screen)
  // ----------------------------------------------------------------------

  static Future<Map<String, dynamic>> createOrder({
    required String shippingAddress,
    required String phone,
    String? discountCode,
    required String paymentMethod,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Không có token xác thực');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.payment}/create-order'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'shipping_address': shippingAddress,
              'phone': phone,
              'discount_code': discountCode,
              'payment_method': paymentMethod,
            }),
          )
          .timeout(ApiConfig.connectTimeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return responseData;
      } else {
        final errorMessage = responseData['error'] ?? 'Lỗi tạo đơn hàng';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Lỗi kết nối hoặc xử lý dữ liệu: $e');
    }
  }

  // ----------------------------------------------------------------------
  // 3. HÀM CHECK STATUS (Cần thiết cho MoMoQRScreen hoặc kiểm tra lại)
  // ----------------------------------------------------------------------

  static Future<Map<String, dynamic>> checkPaymentStatus(
    String paymentCode,
  ) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Không có token xác thực');
    }
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.payment}/check-momo-status/$paymentCode'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(ApiConfig.connectTimeout);

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
          responseData['error'] ?? 'Không thể kiểm tra trạng thái',
        );
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}

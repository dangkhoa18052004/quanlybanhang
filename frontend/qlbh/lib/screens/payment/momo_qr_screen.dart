import 'package:http/http.dart' as http;
import 'package:qlbh/config/api_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  // Hàm trợ giúp lấy Token từ SharedPreferences (Giả định)
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Thay 'auth_token' bằng key bạn dùng để lưu JWT
    return prefs.getString('auth_token');
  }

  // ----------------------------------------------------------------------
  // 1. GỌI API KHỞI TẠO MOMO QR
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
            Uri.parse('${ApiConfig.payment}/initiate-momo-qr'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'payment_code': paymentCode}),
          )
          .timeout(ApiConfig.connectTimeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Trả về dữ liệu thành công (bao gồm qr_code_image, deep_link)
        return responseData;
      } else {
        // Xử lý lỗi từ Backend (ví dụ: 400 Bad Request)
        final errorMessage = responseData['error'] ?? 'Lỗi khởi tạo thanh toán';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Lỗi kết nối hoặc xử lý dữ liệu: $e');
    }
  }

  // ----------------------------------------------------------------------
  // 2. GỌI API KIỂM TRA TRẠNG THÁI THANH TOÁN
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
        // Trả về dữ liệu trạng thái (bao gồm status)
        return responseData;
      } else {
        // Xử lý lỗi
        final errorMessage =
            responseData['error'] ?? 'Không thể kiểm tra trạng thái';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Lỗi kết nối hoặc xử lý dữ liệu: $e');
    }
  }

  // ----------------------------------------------------------------------
  // 3. (Tùy chọn) Hàm Tạo đơn hàng
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
}

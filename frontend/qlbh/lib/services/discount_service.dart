// lib/services/discount_service.dart
import '../config/api_config.dart';
import '../models/discount_code.dart';
import 'api_service.dart';

class DiscountService {
  // Validate discount code
  static Future<Map<String, dynamic>> validateCode({
    required String code,
    required double orderTotal,
  }) async {
    final response = await ApiService.post(
      '${ApiConfig.baseUrl}/discount/validate',
      body: {'code': code, 'order_total': orderTotal},
      needsAuth: true,
    );

    return response;
  }

  // Get available discount codes
  static Future<List<DiscountCode>> getAvailableCodes() async {
    final response = await ApiService.get(
      '${ApiConfig.baseUrl}/discount/available',
      needsAuth: true,
    );

    final List<dynamic> codesJson = response['codes'];
    return codesJson.map((json) => DiscountCode.fromJson(json)).toList();
  }

  // Get all discount codes (admin only)
  static Future<List<DiscountCode>> getAllCodes() async {
    final response = await ApiService.get(
      '${ApiConfig.baseUrl}/discount',
      needsAuth: true,
    );

    final List<dynamic> codesJson = response['codes'];
    return codesJson.map((json) => DiscountCode.fromJson(json)).toList();
  }

  // Create discount code (admin only)
  static Future<DiscountCode> createCode({
    required String code,
    required String discountType,
    required double discountValue,
    String? description,
    double? minOrderValue,
    double? maxDiscountAmount,
    int? usageLimit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await ApiService.post(
      '${ApiConfig.baseUrl}/discount',
      body: {
        'code': code,
        'discount_type': discountType,
        'discount_value': discountValue,
        'description': description,
        'min_order_value': minOrderValue,
        'max_discount_amount': maxDiscountAmount,
        'usage_limit': usageLimit,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      },
      needsAuth: true,
    );

    return DiscountCode.fromJson(response['discount']);
  }

  // Update discount code (admin only)
  static Future<DiscountCode> updateCode({
    required int id,
    Map<String, dynamic>? updates,
  }) async {
    final response = await ApiService.put(
      '${ApiConfig.baseUrl}/discount/$id',
      body: updates ?? {},
      needsAuth: true,
    );

    return DiscountCode.fromJson(response['discount']);
  }

  // Delete discount code (admin only)
  static Future<void> deleteCode(int id) async {
    await ApiService.delete(
      '${ApiConfig.baseUrl}/discount/$id',
      needsAuth: true,
    );
  }

  // Get discount stats (admin only)
  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiService.get(
      '${ApiConfig.baseUrl}/discount/stats',
      needsAuth: true,
    );

    return response;
  }
}

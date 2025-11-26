// lib/services/order_service.dart
import '../config/api_config.dart';
import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  // Get orders
  static Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final queryParams = {'page': page.toString(), 'limit': limit.toString()};

    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await ApiService.get(
      ApiConfig.orders,
      needsAuth: true,
      queryParams: queryParams,
    );

    final List<dynamic> ordersJson = response['orders'];
    final orders = ordersJson.map((json) => Order.fromJson(json)).toList();

    return {'orders': orders, 'pagination': response['pagination']};
  }

  // Get order detail
  static Future<Order> getOrderDetail(int orderId) async {
    final response = await ApiService.get(
      '${ApiConfig.orders}/$orderId',
      needsAuth: true,
    );

    return Order.fromJson(response['order']);
  }

  // Cancel order
  static Future<void> cancelOrder(int orderId) async {
    await ApiService.post(
      '${ApiConfig.orders}/$orderId/cancel',
      body: {},
      needsAuth: true,
    );
  }
}

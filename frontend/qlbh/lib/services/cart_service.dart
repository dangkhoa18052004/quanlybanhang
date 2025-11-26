// lib/services/cart_service.dart
import '../config/api_config.dart';
import '../models/cart_item.dart';
import 'api_service.dart';

class CartService {
  // Get cart
  static Future<Map<String, dynamic>> getCart() async {
    final response = await ApiService.get(ApiConfig.cart, needsAuth: true);

    final List<dynamic> itemsJson = response['items'];
    final items = itemsJson.map((json) => CartItem.fromJson(json)).toList();

    return {
      'items': items,
      'total': response['total'],
      'count': response['count'],
    };
  }

  // Add to cart
  static Future<void> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    await ApiService.post(
      '${ApiConfig.cart}/add',
      body: {'product_id': productId, 'quantity': quantity},
      needsAuth: true,
    );
  }

  // Update cart item
  static Future<void> updateCartItem({
    required int cartId,
    required int quantity,
  }) async {
    await ApiService.put(
      '${ApiConfig.cart}/update/$cartId',
      body: {'quantity': quantity},
      needsAuth: true,
    );
  }

  // Remove from cart
  static Future<void> removeFromCart(int cartId) async {
    await ApiService.delete(
      '${ApiConfig.cart}/remove/$cartId',
      needsAuth: true,
    );
  }

  // Clear cart
  static Future<void> clearCart() async {
    await ApiService.delete('${ApiConfig.cart}/clear', needsAuth: true);
  }
}

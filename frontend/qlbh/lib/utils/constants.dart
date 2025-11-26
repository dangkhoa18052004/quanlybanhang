// lib/utils/constants.dart
class AppConstants {
  static const String appName = 'E-Shop';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxCartQuantity = 10;

  // Pagination
  static const int productsPerPage = 20;
  static const int ordersPerPage = 10;
}

// Order Status
enum OrderStatus { pending, confirmed, shipping, delivered, cancelled }

// Payment Status
enum PaymentStatus { pending, processing, completed, failed }

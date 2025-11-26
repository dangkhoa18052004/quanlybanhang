class ApiConfig {
  // static const String baseUrl = 'http://192.168.100.151:5000/api';

  //  dùng Android Emulator
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static const String auth = '$baseUrl/auth';
  static const String products = '$baseUrl/products';
  static const String categories = '$baseUrl/categories';
  static const String cart = '$baseUrl/cart';
  static const String orders = '$baseUrl/orders';
  static const String reviews = '$baseUrl/reviews';
  static const String payment = '$baseUrl/payment';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

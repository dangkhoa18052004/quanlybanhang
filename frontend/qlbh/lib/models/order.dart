// lib/models/order.dart
class Order {
  final int id;
  final String orderNumber;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final String? discountCode;
  final String shippingAddress;
  final String phone;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String createdAt;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    this.discountCode,
    required this.shippingAddress,
    required this.phone,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      return Order(
        id: _parseInt(json['id']),
        orderNumber: json['order_number']?.toString() ?? '',
        subtotal: _parseDouble(json['subtotal']),
        discountAmount: _parseDouble(json['discount_amount']),
        totalAmount: _parseDouble(json['total_amount']),
        discountCode: json['discount_code']?.toString(),
        shippingAddress: json['shipping_address']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        paymentStatus: json['payment_status']?.toString() ?? 'pending',
        paymentMethod: json['payment_method']?.toString() ?? 'cod',
        createdAt: json['created_at']?.toString() ?? '',
        items: json['items'] != null
            ? (json['items'] as List)
                  .map((item) => OrderItem.fromJson(item))
                  .toList()
            : null,
      );
    } catch (e) {
      print('[ORDER PARSE ERROR] $e');
      print('[ORDER JSON] $json');
      rethrow;
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class OrderItem {
  final int? id; // ✅ NULLABLE - Backend không trả về!
  final int productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final double subtotal;

  OrderItem({
    this.id, // ✅ NULLABLE
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    try {
      return OrderItem(
        // ✅ ID CÓ THỂ NULL
        id: json['id'] != null ? Order._parseInt(json['id']) : null,
        productId: Order._parseInt(json['product_id']),
        productName: json['product_name']?.toString() ?? '',
        productImage: json['product_image']?.toString(),
        price: Order._parseDouble(json['price']),
        quantity: Order._parseInt(json['quantity']),
        subtotal: Order._parseDouble(json['subtotal']),
      );
    } catch (e) {
      print('[ORDER ITEM PARSE ERROR] $e');
      print('[ORDER ITEM JSON] $json');
      rethrow;
    }
  }
}

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
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      subtotal: double.parse(json['subtotal'].toString()),
      discountAmount: double.parse(json['discount_amount'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      discountCode: json['discount_code'],
      shippingAddress: json['shipping_address'],
      phone: json['phone'],
      status: json['status'],
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      createdAt: json['created_at'],
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => OrderItem.fromJson(item))
                .toList()
          : null,
    );
  }
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productImage: json['product_image'],
      price: double.parse(json['price'].toString()),
      quantity: json['quantity'],
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}

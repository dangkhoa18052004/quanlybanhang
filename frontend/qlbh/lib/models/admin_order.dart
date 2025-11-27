// lib/models/admin_order.dart
class AdminOrder {
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
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final List<AdminOrderItem>? items;
  final Map<String, dynamic>? payment;

  AdminOrder({
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
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.items,
    this.payment,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
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
      customerName: json['customer_name']?.toString() ?? '',
      customerEmail: json['customer_email']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString(),
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => AdminOrderItem.fromJson(item))
                .toList()
          : null,
      payment: json['payment'] as Map<String, dynamic>?,
    );
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

class AdminOrderItem {
  final int? id;
  final int productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final double subtotal;

  AdminOrderItem({
    this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) {
    return AdminOrderItem(
      id: json['id'] != null ? AdminOrder._parseInt(json['id']) : null,
      productId: AdminOrder._parseInt(json['product_id']),
      productName: json['product_name']?.toString() ?? '',
      productImage: json['product_image']?.toString(),
      price: AdminOrder._parseDouble(json['price']),
      quantity: AdminOrder._parseInt(json['quantity']),
      subtotal: AdminOrder._parseDouble(json['subtotal']),
    );
  }
}

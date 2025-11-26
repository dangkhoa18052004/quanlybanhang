class CartItem {
  final int id;
  final int productId;
  final String productName;
  final double price;
  final String? imageUrl;
  int quantity;
  final int stockQuantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    this.imageUrl,
    required this.quantity,
    required this.stockQuantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      price: double.parse(json['price'].toString()),
      imageUrl: json['image_url'],
      quantity: json['quantity'],
      stockQuantity: json['stock_quantity'] ?? 0,
    );
  }

  double get subtotal => price * quantity;
}

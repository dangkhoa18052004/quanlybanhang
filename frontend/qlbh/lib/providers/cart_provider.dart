// lib/providers/cart_provider.dart
import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  double _total = 0;
  int _count = 0;

  bool _isLoading = false;
  String? _error;

  // Getters
  List<CartItem> get items => _items;
  double get total => _total;
  int get count => _count;
  int get itemCount => _count;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty;

  // Load cart
  Future<void> loadCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await CartService.getCart();
      _items = result['items'];
      _total = result['total'];
      _count = result['count'];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add to cart
  Future<bool> addToCart(int productId, {int quantity = 1}) async {
    try {
      await CartService.addToCart(productId: productId, quantity: quantity);
      await loadCart();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update quantity
  Future<bool> updateQuantity(int cartId, int quantity) async {
    if (quantity < 1) return false;

    try {
      await CartService.updateCartItem(cartId: cartId, quantity: quantity);

      // Update local state immediately for better UX
      final index = _items.indexWhere((item) => item.id == cartId);
      if (index != -1) {
        _items[index].quantity = quantity;
        _calculateTotal();
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove item
  Future<bool> removeItem(int cartId) async {
    try {
      await CartService.removeFromCart(cartId);

      // Update local state
      _items.removeWhere((item) => item.id == cartId);
      _count = _items.length;
      _calculateTotal();
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      await CartService.clearCart();
      _items.clear();
      _total = 0;
      _count = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Calculate total locally
  void _calculateTotal() {
    _total = _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

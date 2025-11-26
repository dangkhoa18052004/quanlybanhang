// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  Order? _selectedOrder;

  bool _isLoading = false;
  String? _error;

  // Getters
  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load orders
  Future<void> loadOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await OrderService.getOrders(status: status);
      _orders = result['orders'];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load order detail
  Future<void> loadOrderDetail(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedOrder = await OrderService.getOrderDetail(orderId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel order
  Future<bool> cancelOrder(int orderId) async {
    try {
      await OrderService.cancelOrder(orderId);
      await loadOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

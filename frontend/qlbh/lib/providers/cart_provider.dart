// lib/providers/product_provider.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Category> _categories = [];
  Product? _selectedProduct;

  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // Getters
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await ProductService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load products
  Future<void> loadProducts({
    bool refresh = false,
    int? categoryId,
    String? search,
    String sortBy = 'newest',
  }) async {
    if (refresh) {
      _currentPage = 1;
      _products.clear();
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ProductService.getProducts(
        page: _currentPage,
        categoryId: categoryId,
        search: search,
        sortBy: sortBy,
      );

      final List<Product> newProducts = result['products'];
      final pagination = result['pagination'];

      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _currentPage = pagination['page'] + 1;
      _totalPages = pagination['total_pages'];
      _hasMore = _currentPage <= _totalPages;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load product detail
  Future<void> loadProductDetail(int productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await ProductService.getProductDetail(productId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    await loadProducts(refresh: true, search: query);
  }

  // Filter by category
  Future<void> filterByCategory(int categoryId) async {
    await loadProducts(refresh: true, categoryId: categoryId);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// lib/services/admin_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'package:http/http.dart' as http;

class AdminService {
  static const String _adminBase = '${ApiConfig.baseUrl}/admin';

  // ✅ Helper method để lấy token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ✅ Helper method để parse response
  static dynamic _parseResponse(String responseData) {
    return jsonDecode(responseData);
  }

  // ==================== PRODUCT MANAGEMENT ====================

  static Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    required int stockQuantity,
    required int categoryId,
    String? imagePath,
  }) async {
    final uri = Uri.parse('$_adminBase/products');
    final request = http.MultipartRequest('POST', uri);

    final token = await _getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['stock_quantity'] = stockQuantity.toString();
    request.fields['category_id'] = categoryId.toString();

    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final json = _parseResponse(responseData);
      return Product.fromJson(json['product']);
    } else {
      throw Exception('Failed to create product');
    }
  }

  static Future<Product> updateProduct({
    required int productId,
    required Map<String, dynamic> updates,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/products/$productId');
    final token = await _getToken();

    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final json = _parseResponse(response.body);
      return Product.fromJson(json['product']);
    } else {
      throw Exception('Failed to update product');
    }
  }

  static Future<void> deleteProduct(int productId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/products/$productId');
    final token = await _getToken();

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }

  // ==================== CATEGORY MANAGEMENT ====================

  static Future<List<Category>> getAllCategories() async {
    final uri = Uri.parse('$_adminBase/categories');
    final token = await _getToken();

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> categoriesJson = json['categories'];
      return categoriesJson.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  static Future<Category> createCategory({
    required String name,
    String? description,
    String? imagePath,
  }) async {
    final uri = Uri.parse('$_adminBase/categories');
    final request = http.MultipartRequest('POST', uri);

    final token = await _getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;

    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final json = _parseResponse(responseData);
      return Category.fromJson(json['category']);
    } else {
      throw Exception('Failed to create category');
    }
  }

  static Future<Category> updateCategory({
    required int categoryId,
    String? name,
    String? description,
    String? imagePath,
  }) async {
    final uri = Uri.parse('$_adminBase/categories/$categoryId');
    final request = http.MultipartRequest('PUT', uri);

    final token = await _getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (name != null) request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;

    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = _parseResponse(responseData);
      return Category.fromJson(json['category']);
    } else {
      throw Exception('Failed to update category');
    }
  }

  static Future<void> deleteCategory(int categoryId) async {
    final uri = Uri.parse('$_adminBase/categories/$categoryId');
    final token = await _getToken();

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete category');
    }
  }

  // ==================== DASHBOARD STATS ====================

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final uri = Uri.parse('$_adminBase/dashboard/stats');
    final token = await _getToken();

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard stats');
    }
  }
}

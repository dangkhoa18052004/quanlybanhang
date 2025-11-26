// lib/services/product_service.dart
import '../config/api_config.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'api_service.dart';

class ProductService {
  // Get categories
  static Future<List<Category>> getCategories() async {
    final response = await ApiService.get('${ApiConfig.categories}');

    final List<dynamic> categoriesJson = response['categories'];
    return categoriesJson.map((json) => Category.fromJson(json)).toList();
  }

  // Get products
  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    int? categoryId,
    String? search,
    String sortBy = 'newest',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sort_by': sortBy,
    };

    if (categoryId != null) {
      queryParams['category_id'] = categoryId.toString();
    }

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await ApiService.get(
      '${ApiConfig.products}',
      queryParams: queryParams,
    );

    final List<dynamic> productsJson = response['products'];
    final products = productsJson
        .map((json) => Product.fromJson(json))
        .toList();

    return {'products': products, 'pagination': response['pagination']};
  }

  // Get product detail
  static Future<Product> getProductDetail(int productId) async {
    final response = await ApiService.get('${ApiConfig.products}/$productId');

    return Product.fromJson(response['product']);
  }
}

// lib/screens/admin/product_management_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qlbh/config/theme_config.dart';
import 'package:qlbh/models/product.dart';
import 'package:qlbh/services/product_service.dart';
import 'package:qlbh/services/admin_service.dart';
import 'package:qlbh/widgets/product_image.dart'; // ✅ Import ProductImage widget
import 'product_form_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ProductService.getProducts(limit: 50);
      setState(() {
        _products = response['products'] as List<Product>;
      });
    } catch (e) {
      setState(() {
        _error =
            'Lỗi tải sản phẩm: ${e.toString().replaceAll('Exception: ', '')}';
      });
      Fluttertoast.showToast(msg: _error!, backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(int productId, String name) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text('Bạn có chắc chắn muốn xóa sản phẩm "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminService.deleteProduct(productId);
        Fluttertoast.showToast(
          msg: 'Xóa sản phẩm thành công!',
          backgroundColor: AppTheme.successColor,
        );
        _fetchProducts();
      } catch (e) {
        Fluttertoast.showToast(
          msg: e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _openProductForm({Product? product}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );

    if (result == true) {
      _fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sản phẩm'),
        backgroundColor: AppTheme.primaryColor,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openProductForm(),
            tooltip: 'Thêm Sản phẩm mới',
          ),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchProducts,
        label: const Text('Làm mới'),
        icon: const Icon(Icons.refresh),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchProducts, child: Text('Thử lại')),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return const Center(child: Text('Không có sản phẩm nào.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80.0),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          child: ListTile(
            // ✅ SỬ DỤNG ProductImage WIDGET
            leading: ProductImage(
              product: product,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
            title: Text(
              product.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  'Giá: ${_formatPrice(product.price)} VNĐ',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tồn kho: ${product.stockQuantity}',
                  style: TextStyle(
                    color: product.stockQuantity < 10
                        ? Colors.red
                        : Colors.grey[700],
                  ),
                ),
                if (product.categoryName != null)
                  Text(
                    'Danh mục: ${product.categoryName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _openProductForm(product: product),
                  tooltip: 'Sửa sản phẩm',
                ),
                // IconButton(
                //   icon: const Icon(Icons.delete, color: Colors.red),
                //   onPressed: () => _confirmDelete(product.id, product.name),
                //   tooltip: 'Xóa sản phẩm',
                // ),
              ],
            ),
            onTap: () {
              // Có thể thêm xem chi tiết sản phẩm ở đây
            },
          ),
        );
      },
    );
  }

  // Helper để format giá tiền
  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

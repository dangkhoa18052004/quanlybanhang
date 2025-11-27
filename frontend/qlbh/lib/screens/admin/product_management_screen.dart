// lib/screens/admin/product_management_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qlbh/config/theme_config.dart';
import 'package:qlbh/models/product.dart';
import 'package:qlbh/services/product_service.dart';
import 'package:qlbh/services/admin_service.dart';
import 'product_form_screen.dart'; // ✅ Import màn hình Form mới

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

  // Hàm tải dữ liệu thật (Giả định đã hoạt động)
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

  // Hàm xóa sản phẩm
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

  // ✅ HÀM MỞ FORM THÊM/SỬA
  void _openProductForm({Product? product}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product), // Gọi form mới
      ),
    );

    if (result == true) {
      _fetchProducts(); // Tải lại danh sách nếu có thay đổi
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
            onPressed: () => _openProductForm(), // ✅ Kết nối nút Thêm
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
      return Center(child: Text(_error!));
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
            leading: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                ? Image.network(
                    product.imageUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
                    ),
                  )
                : const Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
            title: Text(product.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giá: ${product.price.toStringAsFixed(0)} VNĐ',
                  style: TextStyle(color: AppTheme.accentColor),
                ),
                Text('Tồn kho: ${product.stockQuantity}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () =>
                      _openProductForm(product: product), // ✅ Nút Sửa
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _confirmDelete(product.id!, product.name), // ✅ Nút Xóa
                ),
              ],
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qlbh/config/theme_config.dart';

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sản phẩm'),
        backgroundColor: AppTheme.primaryColor,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // TODO: Điều hướng đến màn hình Thêm Sản phẩm mới
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng Thêm Sản phẩm')),
              );
            },
            tooltip: 'Thêm Sản phẩm mới',
          ),
        ],
      ),
      body: _buildProductList(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Gọi API để tải lại/làm mới danh sách sản phẩm
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đang tải lại danh sách...')),
          );
        },
        label: const Text('Làm mới'),
        icon: const Icon(Icons.refresh),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    // Dữ liệu giả (mock data) - Thay thế bằng việc gọi API thật sau này
    final List<Map<String, dynamic>> mockProducts = [
      {
        'id': 1,
        'name': 'Áo Thun Basic',
        'price': 150000.0,
        'stock': 100,
        'imageUrl': 'placeholder_url',
      },
      {
        'id': 2,
        'name': 'Quần Jeans Slimfit',
        'price': 550000.0,
        'stock': 50,
        'imageUrl': 'placeholder_url',
      },
      {
        'id': 3,
        'name': 'Giày Sneaker Trắng',
        'price': 990000.0,
        'stock': 30,
        'imageUrl': 'placeholder_url',
      },
    ];

    if (mockProducts.isEmpty) {
      return const Center(child: Text('Không có sản phẩm nào.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80.0),
      itemCount: mockProducts.length,
      itemBuilder: (context, index) {
        final product = mockProducts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          child: ListTile(
            leading: const Icon(
              Icons.image_outlined,
              size: 40,
              color: Colors.grey,
            ),
            title: Text(product['name']!),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giá: ${product['price']} VNĐ',
                  style: TextStyle(color: AppTheme.accentColor),
                ),
                Text('Tồn kho: ${product['stock']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // TODO: Chức năng Sửa
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // TODO: Chức năng Xóa (cần có xác nhận)
                  },
                ),
              ],
            ),
            onTap: () {
              // TODO: Chức năng Xem chi tiết quản lý
            },
          ),
        );
      },
    );
  }
}

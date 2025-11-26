import 'package:flutter/material.dart';
import 'package:qlbh/config/theme_config.dart';
import 'package:qlbh/screens/admin/product_management_screen.dart';
// Import các màn hình quản lý khác khi bạn tạo ra

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: ThemeConfig.primaryColor,
        automaticallyImplyLeading:
            false, // Thường không có nút Back trên Dashboard
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildManagementTile(
            context,
            icon: Icons.inventory_2,
            title: 'Quản lý Sản phẩm',
            subtitle: 'Thêm, sửa, xóa sản phẩm',
            destination: const ProductManagementScreen(),
          ),
          _buildManagementTile(
            context,
            icon: Icons.category,
            title: 'Quản lý Danh mục',
            subtitle: 'Thêm, sửa, xóa danh mục sản phẩm',
            // destination: const CategoryManagementScreen(), // Tùy chọn 2
          ),
          _buildManagementTile(
            context,
            icon: Icons.receipt_long,
            title: 'Quản lý Đơn hàng',
            subtitle: 'Xem và cập nhật trạng thái đơn hàng',
            // destination: const OrderManagementScreen(), // Tùy chọn 3
          ),
          _buildManagementTile(
            context,
            icon: Icons.people,
            title: 'Quản lý Người dùng',
            subtitle: 'Quản lý tài khoản người dùng',
            // destination: const UserManagementScreen(), // Tùy chọn 4
          ),
          _buildManagementTile(
            context,
            icon: Icons.discount,
            title: 'Quản lý Mã giảm giá',
            subtitle: 'Tạo, sửa, xóa mã giảm giá',
            // destination: const CouponManagementScreen(), // Tùy chọn 5
          ),
          // Bạn có thể thêm các chức năng thống kê/báo cáo ở đây
        ],
      ),
    );
  }

  Widget _buildManagementTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? destination,
  }) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Icon(icon, color: ThemeConfig.primaryColor, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (destination != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          } else {
            // Thông báo nếu màn hình chưa được triển khai
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Màn hình "$title" chưa được triển khai.'),
              ),
            );
          }
        },
      ),
    );
  }
}

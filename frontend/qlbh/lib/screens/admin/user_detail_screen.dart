// lib/screens/admin/user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/theme_config.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';
import 'user_form_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  const UserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late User _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  // ✅ CẬP NHẬT ROLE
  Future<void> _toggleRole() async {
    final newRole = _user.role == 'admin' ? 'customer' : 'admin';

    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật quyền hạn'),
        content: Text(
          'Bạn có chắc muốn chuyển người dùng này thành "$newRole"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Xác nhận',
              style: TextStyle(
                color: newRole == 'admin' ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await AdminService.updateUserRole(userId: _user.id, role: newRole);
        setState(() {
          _user = User(
            id: _user.id,
            email: _user.email,
            fullName: _user.fullName,
            phone: _user.phone,
            address: _user.address,
            role: newRole,
            createdAt: _user.createdAt,
          );
        });
        Fluttertoast.showToast(
          msg: 'Cập nhật quyền thành công!',
          backgroundColor: AppTheme.successColor,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ MỞ FORM SỬA
  void _editUser() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => UserFormScreen(user: _user)));

    if (result == true) {
      Navigator.pop(context, true); // Quay lại và reload
    }
  }

  // ✅ XÓA NGƯỜI DÙNG
  Future<void> _deleteUser() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa người dùng "${_user.fullName}"?',
        ),
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
      setState(() => _isLoading = true);
      try {
        await AdminService.deleteUser(_user.id);
        Fluttertoast.showToast(
          msg: 'Xóa người dùng thành công!',
          backgroundColor: AppTheme.successColor,
        );
        Navigator.pop(context, true); // Quay lại và reload
      } catch (e) {
        Fluttertoast.showToast(
          msg: e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = _user.role == 'customer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Người dùng'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editUser,
            tooltip: 'Sửa thông tin',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteUser,
            tooltip: 'Xóa người dùng',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar và Tên
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: isCustomer
                              ? Colors.blue.shade100
                              : Colors.red.shade100,
                          child: Text(
                            _user.fullName.isNotEmpty
                                ? _user.fullName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: isCustomer ? Colors.blue : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _user.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isCustomer
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCustomer ? 'KHÁCH HÀNG' : 'QUẢN TRỊ VIÊN',
                            style: TextStyle(
                              color: isCustomer
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Thông tin chi tiết
                  _buildInfoCard(
                    icon: Icons.email,
                    label: 'Email',
                    value: _user.email,
                  ),
                  const SizedBox(height: 16),

                  if (_user.phone != null)
                    _buildInfoCard(
                      icon: Icons.phone,
                      label: 'Số điện thoại',
                      value: _user.phone!,
                    ),
                  if (_user.phone != null) const SizedBox(height: 16),

                  if (_user.address != null)
                    _buildInfoCard(
                      icon: Icons.location_on,
                      label: 'Địa chỉ',
                      value: _user.address!,
                    ),
                  if (_user.address != null) const SizedBox(height: 16),

                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    label: 'Ngày tạo',
                    value: _user.createdAt != null
                        ? _formatDate(_user.createdAt!)
                        : 'N/A',
                  ),
                  const SizedBox(height: 32),

                  // Nút chuyển đổi quyền
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleRole,
                      icon: Icon(isCustomer ? Icons.star : Icons.star_border),
                      label: Text(
                        isCustomer
                            ? 'NÂNG CẤP LÊN ADMIN'
                            : 'HẠ CẤP XUỐNG CUSTOMER',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCustomer
                            ? Colors.green
                            : Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

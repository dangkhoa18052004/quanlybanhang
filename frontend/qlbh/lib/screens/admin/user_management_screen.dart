// lib/screens/admin/user_management_screen.dart (CODE HOÀN THIỆN)

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qlbh/config/theme_config.dart';
import 'package:qlbh/models/user.dart'; // ✅ Cần import model User
import 'package:qlbh/services/admin_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;
  String _selectedRoleFilter = 'all'; // all, customer, admin
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Trì hoãn việc fetch để tránh gọi API quá nhiều lần khi người dùng đang gõ
    // (Thực tế nên dùng debounce, nhưng ở đây ta dùng fetch ngay)
    _fetchUsers(search: _searchController.text);
  }

  // ✅ HÀM GỌI API LẤY DANH SÁCH USER
  Future<void> _fetchUsers({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Lọc theo role (trừ 'all')
    final roleFilter = _selectedRoleFilter == 'all'
        ? null
        : _selectedRoleFilter;

    try {
      final response = await AdminService.getAllUsers(
        role: roleFilter,
        search: search,
        // Có thể thêm page/limit nếu muốn
      );

      setState(() {
        _users = response['users'] as List<User>;
      });
    } catch (e) {
      setState(() {
        _error =
            'Lỗi tải danh sách người dùng: ${e.toString().replaceAll('Exception: ', '')}';
      });
      Fluttertoast.showToast(msg: _error!, backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ HÀM CẬP NHẬT ROLE
  Future<void> _updateRole(int userId, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'customer' : 'admin';

    // Yêu cầu xác nhận (Tùy chọn)
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
      try {
        await AdminService.updateUserRole(userId: userId, role: newRole);
        Fluttertoast.showToast(
          msg: 'Cập nhật quyền thành công!',
          backgroundColor: AppTheme.successColor,
        );
        _fetchUsers(); // Tải lại danh sách
      } catch (e) {
        Fluttertoast.showToast(
          msg: e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // Filter & Search
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Tìm kiếm theo Tên/Email',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRoleFilter,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Tất cả Users'),
                        ),
                        DropdownMenuItem(
                          value: 'customer',
                          child: Text('Khách hàng'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Quản trị viên'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRoleFilter = value;
                          });
                          _fetchUsers(search: _searchController.text);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchUsers,
        label: const Text('Làm mới'),
        icon: const Icon(Icons.refresh),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_users.isEmpty) {
      return const Center(child: Text('Không tìm thấy người dùng nào.'));
    }

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isCustomer = user.role == 'customer';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCustomer
                  ? Colors.blue.shade100
                  : Colors.red.shade100,
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                style: TextStyle(color: isCustomer ? Colors.blue : Colors.red),
              ),
            ),
            title: Text(user.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: const TextStyle(fontSize: 12)),
                Text(
                  'SĐT: ${user.phone ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCustomer
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCustomer ? 'Customer' : 'Admin',
                    style: TextStyle(
                      color: isCustomer
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isCustomer ? Icons.star_border : Icons.star,
                    color: isCustomer ? Colors.grey : Colors.red,
                  ),
                  onPressed: () =>
                      _updateRole(user.id!, user.role), // ✅ Nút chuyển đổi Role
                  tooltip: isCustomer
                      ? 'Nâng cấp lên Admin'
                      : 'Hạ cấp xuống Customer',
                ),
              ],
            ),
            onTap: () {
              // TODO: Điều hướng đến màn hình chi tiết người dùng nếu cần
              Fluttertoast.showToast(msg: 'Xem chi tiết ${user.fullName}');
            },
          ),
        );
      },
    );
  }
}

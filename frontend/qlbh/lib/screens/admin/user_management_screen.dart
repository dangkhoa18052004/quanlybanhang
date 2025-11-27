// lib/screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qlbh/config/theme_config.dart';
import 'package:qlbh/models/user.dart';
import 'package:qlbh/services/admin_service.dart';
import 'user_form_screen.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;
  String _selectedRoleFilter = 'all';
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
    _fetchUsers(search: _searchController.text);
  }

  Future<void> _fetchUsers({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final roleFilter = _selectedRoleFilter == 'all'
        ? null
        : _selectedRoleFilter;

    try {
      final response = await AdminService.getAllUsers(
        role: roleFilter,
        search: search,
      );

      setState(() {
        _users = response['users'] as List<User>;
      });
    } catch (e) {
      setState(() {
        _error =
            'Lỗi tải danh sách: ${e.toString().replaceAll('Exception: ', '')}';
      });
      Fluttertoast.showToast(msg: _error!, backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ MỞ FORM THÊM/SỬA
  void _openUserForm({User? user}) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => UserFormScreen(user: user)));

    if (result == true) {
      _fetchUsers();
    }
  }

  // ✅ MỞ MÀN HÌNH CHI TIẾT
  void _openUserDetail(User user) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)));

    if (result == true) {
      _fetchUsers(); // Reload nếu có thay đổi
    }
  }

  // ✅ XÓA NGƯỜI DÙNG
  Future<void> _confirmDelete(int userId, String name) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng "$name"?'),
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
        await AdminService.deleteUser(userId);
        Fluttertoast.showToast(
          msg: 'Xóa người dùng thành công!',
          backgroundColor: AppTheme.successColor,
        );
        _fetchUsers();
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
        actions: [
          // ✅ NÚT THÊM NGƯỜI DÙNG
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _openUserForm(),
            tooltip: 'Thêm người dùng mới',
          ),
        ],
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
                        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        DropdownMenuItem(
                          value: 'customer',
                          child: Text('Khách hàng'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRoleFilter = value);
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchUsers, child: Text('Thử lại')),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return const Center(child: Text('Không tìm thấy người dùng nào.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
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
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: isCustomer ? Colors.blue : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user.fullName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: const TextStyle(fontSize: 12)),
                if (user.phone != null)
                  Text(
                    'SĐT: ${user.phone}',
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
                      fontSize: 12,
                    ),
                  ),
                ),
                // ✅ NÚT XEM CHI TIẾT
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  onPressed: () => _openUserDetail(user),
                  tooltip: 'Xem chi tiết',
                ),
                // NÚT SỬA
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _openUserForm(user: user),
                  tooltip: 'Sửa người dùng',
                ),
                // NÚT XÓA
                // IconButton(
                //   icon: const Icon(Icons.delete, color: Colors.red),
                //   onPressed: () => _confirmDelete(user.id!, user.fullName),
                //   tooltip: 'Xóa người dùng',
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
}

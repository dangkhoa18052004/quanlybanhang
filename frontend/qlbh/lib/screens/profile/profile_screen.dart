// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme_config.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<AuthProvider>().logout();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              // Show QR code for user profile
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Mã QR của bạn'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code, size: 150),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.fullName ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        user?.fullName[0].toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (user?.phone != null)
                          Text(
                            user!.phone!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.receipt_long,
                      label: 'Đơn hàng',
                      value: '0',
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.favorite,
                      label: 'Yêu thích',
                      value: '0',
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.discount,
                      label: 'Voucher',
                      value: '0',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Menu Items
            _buildSection('Tài khoản'),
            _buildMenuItem(
              context,
              icon: Icons.person_outline,
              title: 'Thông tin cá nhân',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                // Refresh if profile was updated
                if (result == true && context.mounted) {
                  context.read<AuthProvider>().initialize();
                }
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.location_on_outlined,
              title: 'Địa chỉ giao hàng',
              subtitle: user?.address ?? 'Chưa có địa chỉ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.lock_outline,
              title: 'Đổi mật khẩu',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),

            const Divider(height: 32),

            _buildSection('Khác'),
            _buildMenuItem(
              context,
              icon: Icons.notifications_outlined,
              title: 'Thông báo',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // Toggle notifications
                },
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.language,
              title: 'Ngôn ngữ',
              subtitle: 'Tiếng Việt',
              onTap: () {
                // Show language picker
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.dark_mode_outlined,
              title: 'Giao diện tối',
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  // Toggle dark mode
                },
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: 'Trợ giúp & Hỗ trợ',
              onTap: () {
                // Navigate to help
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Chính sách & Điều khoản',
              onTap: () {
                // Navigate to policies
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.info_outline,
              title: 'Về chúng tôi',
              onTap: () {
                // Navigate to about
              },
            ),

            const Divider(height: 32),

            // Logout
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Đăng xuất',
              titleColor: Colors.red,
              showArrow: false,
              onTap: () => _logout(context),
            ),

            const SizedBox(height: 16),

            // Version
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (titleColor ?? AppTheme.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: titleColor ?? AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, color: titleColor)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      trailing:
          trailing ??
          (showArrow
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null),
      onTap: trailing == null ? onTap : null,
    );
  }
}

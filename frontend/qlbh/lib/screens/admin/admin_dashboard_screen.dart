// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme_config.dart';
import '../../services/admin_service.dart';
import '../../utils/helpers.dart';
import 'product_management_screen.dart';
import 'category_management_screen.dart';
import 'order_management_screen.dart';
import 'user_management_screen.dart';
import 'discount_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await AdminService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $_error'),
                  ElevatedButton(
                    onPressed: _loadStats,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildRevenueChart(),
                  const SizedBox(height: 24),
                  _buildTopProducts(),
                  const SizedBox(height: 24),
                  _buildManagementSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCards() {
    final stats = _stats!['stats'];

    String _parseValue(dynamic value) {
      if (value == null) return '0';
      if (value is num) return value.toString();
      if (value is String) return value;
      return '0';
    }

    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Doanh thu',
          value: Helpers.formatCurrency(_parseDouble(stats['total_revenue'])),
          icon: Icons.attach_money,
          color: AppTheme.successColor,
        ),
        _StatCard(
          title: 'Đơn hàng',
          value: _parseValue(stats['total_orders']),
          subtitle: '${_parseValue(stats['pending_orders'])} chờ xử lý',
          icon: Icons.shopping_cart,
          color: AppTheme.primaryColor,
        ),
        _StatCard(
          title: 'Sản phẩm',
          value: _parseValue(stats['total_products']),
          subtitle: '${_parseValue(stats['low_stock_products'])} sắp hết',
          icon: Icons.inventory,
          color: AppTheme.accentColor,
        ),
        _StatCard(
          title: 'Khách hàng',
          value: _parseValue(stats['total_customers']),
          icon: Icons.people,
          color: AppTheme.secondaryColor,
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    final dailyRevenue = _stats!['daily_revenue'] as List;

    if (dailyRevenue.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doanh thu 7 ngày gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dailyRevenue.length) {
                            return const Text('');
                          }
                          final date =
                              dailyRevenue[index]['date']?.toString() ?? '';
                          final parts = date.split('-');
                          if (parts.length < 3) return const Text('');
                          return Text(
                            '${parts[2]}/${parts[1]}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(dailyRevenue.length, (index) {
                        // ✅ Parse an toàn revenue từ String/int/double
                        final revenueValue = dailyRevenue[index]['revenue'];
                        double revenue = 0.0;

                        if (revenueValue is num) {
                          revenue = revenueValue.toDouble();
                        } else if (revenueValue is String) {
                          revenue = double.tryParse(revenueValue) ?? 0.0;
                        }

                        return FlSpot(index.toDouble(), revenue);
                      }),
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts() {
    final topProducts = _stats!['top_products'] as List;

    if (topProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ Helper để parse số
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top sản phẩm bán chạy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...topProducts.map(
              (product) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: product['image_url'] != null
                      ? NetworkImage(
                          'http://10.0.2.2:5000${product['image_url']}',
                        )
                      : null,
                  child: product['image_url'] == null
                      ? const Icon(Icons.image)
                      : null,
                ),
                title: Text(product['name']?.toString() ?? ''),
                subtitle: Text(
                  Helpers.formatCurrency(_parseDouble(product['price'])),
                ),
                trailing: Text(
                  '${product['total_sold']?.toString() ?? '0'} đã bán',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quản lý',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _ManagementCard(
          icon: Icons.inventory_2,
          title: 'Quản lý Sản phẩm',
          subtitle: 'Thêm, sửa, xóa sản phẩm',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductManagementScreen()),
          ),
        ),
        _ManagementCard(
          icon: Icons.category,
          title: 'Quản lý Danh mục',
          subtitle: 'Quản lý danh mục sản phẩm',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
          ),
        ),
        _ManagementCard(
          icon: Icons.receipt_long,
          title: 'Quản lý Đơn hàng',
          subtitle: 'Xem và cập nhật đơn hàng',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrderManagementScreen()),
          ),
        ),
        _ManagementCard(
          icon: Icons.people,
          title: 'Quản lý Người dùng',
          subtitle: 'Quản lý tài khoản người dùng',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserManagementScreen()),
          ),
        ),
        _ManagementCard(
          icon: Icons.discount,
          title: 'Quản lý Mã giảm giá',
          subtitle: 'Tạo và quản lý mã giảm giá',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DiscountManagementScreen()),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

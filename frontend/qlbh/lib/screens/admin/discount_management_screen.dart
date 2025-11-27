// lib/screens/admin/discount_management_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/theme_config.dart';
import '../../models/discount_code.dart';
import '../../services/admin_service.dart';
import 'discount_form_screen.dart';
import 'discount_detail_screen.dart';

class DiscountManagementScreen extends StatefulWidget {
  const DiscountManagementScreen({Key? key}) : super(key: key);

  @override
  State<DiscountManagementScreen> createState() =>
      _DiscountManagementScreenState();
}

class _DiscountManagementScreenState extends State<DiscountManagementScreen> {
  List<DiscountCode> _discounts = [];
  List<DiscountCode> _filteredDiscounts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    _loadDiscounts();
  }

  Future<void> _loadDiscounts() async {
    setState(() => _isLoading = true);
    try {
      final discounts = await AdminService.getAllDiscountCodes();
      setState(() {
        _discounts = discounts;
        _applyFilters();
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Lỗi tải dữ liệu: ${e.toString().replaceAll('Exception: ', '')}',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredDiscounts = _discounts.where((discount) {
      // Filter by search query
      final matchesSearch =
          _searchQuery.isEmpty ||
          discount.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (discount.description?.toLowerCase() ?? '').contains(
            _searchQuery.toLowerCase(),
          );

      // Filter by status
      final matchesStatus =
          _filterStatus == 'all' ||
          (_filterStatus == 'active' && discount.isActive == true) ||
          (_filterStatus == 'inactive' && discount.isActive == false);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onFilterChanged(String? filter) {
    if (filter != null) {
      setState(() {
        _filterStatus = filter;
        _applyFilters();
      });
    }
  }

  Future<void> _openDiscountForm({DiscountCode? discount}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscountFormScreen(discount: discount),
      ),
    );

    if (result == true) {
      _loadDiscounts();
    }
  }

  Future<void> _openDiscountDetail(DiscountCode discount) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscountDetailScreen(discount: discount),
      ),
    );

    if (result == true) {
      _loadDiscounts();
    }
  }

  Future<void> _confirmDelete(DiscountCode discount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa mã "${discount.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminService.deleteDiscountCode(discount.id!);
        Fluttertoast.showToast(
          msg: 'Đã xóa mã giảm giá',
          backgroundColor: AppTheme.successColor,
        );
        _loadDiscounts();
      } catch (e) {
        Fluttertoast.showToast(
          msg: e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _toggleStatus(DiscountCode discount) async {
    try {
      await AdminService.updateDiscountCode(
        discountId: discount.id!,
        isActive: !(discount.isActive ?? false),
      );
      Fluttertoast.showToast(
        msg: 'Đã cập nhật trạng thái',
        backgroundColor: AppTheme.successColor,
      );
      _loadDiscounts();
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Mã giảm giá'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openDiscountForm(),
            tooltip: 'Thêm mã giảm giá',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiscounts,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm mã giảm giá...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                // Filter Chips
                Row(
                  children: [
                    const Text('Lọc: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Tất cả'),
                            selected: _filterStatus == 'all',
                            onSelected: (_) => _onFilterChanged('all'),
                          ),
                          ChoiceChip(
                            label: const Text('Đang hoạt động'),
                            selected: _filterStatus == 'active',
                            onSelected: (_) => _onFilterChanged('active'),
                          ),
                          ChoiceChip(
                            label: const Text('Tạm ngưng'),
                            selected: _filterStatus == 'inactive',
                            onSelected: (_) => _onFilterChanged('inactive'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Discount List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDiscounts.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadDiscounts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredDiscounts.length,
                      itemBuilder: (context, index) {
                        return _buildDiscountCard(_filteredDiscounts[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDiscountForm(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Tạo mã mới'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.discount_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có mã giảm giá',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _openDiscountForm(),
            icon: const Icon(Icons.add),
            label: const Text('Tạo mã đầu tiên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard(DiscountCode discount) {
    final isExpired = discount.isExpired;
    final isActive = discount.isActive ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openDiscountDetail(discount),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Code Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      discount.code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Discount Value
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      discount.displayDiscount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? Colors.grey
                          : isActive
                          ? AppTheme.successColor
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isExpired
                          ? 'Hết hạn'
                          : isActive
                          ? 'Hoạt động'
                          : 'Tạm ngưng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Description
              if (discount.description != null &&
                  discount.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  discount.description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              // Info Row
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.shopping_cart,
                    discount.displayCondition,
                    Colors.blue,
                  ),
                  if (discount.usageLimit != null)
                    _buildInfoChip(
                      Icons.people,
                      '${discount.usedCount ?? 0}/${discount.usageLimit}',
                      Colors.purple,
                    ),
                  if (discount.endDate != null)
                    _buildInfoChip(
                      Icons.calendar_today,
                      'Đến ${_formatDate(discount.endDate!)}',
                      Colors.orange,
                    ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // View Detail
                  TextButton.icon(
                    onPressed: () => _openDiscountDetail(discount),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Chi tiết'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),

                  // Edit
                  TextButton.icon(
                    onPressed: () => _openDiscountForm(discount: discount),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Sửa'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),

                  // Toggle Status
                  TextButton.icon(
                    onPressed: () => _toggleStatus(discount),
                    icon: Icon(
                      isActive ? Icons.pause_circle : Icons.play_circle,
                      size: 18,
                    ),
                    label: Text(isActive ? 'Tắt' : 'Bật'),
                    style: TextButton.styleFrom(
                      foregroundColor: isActive
                          ? Colors.orange
                          : AppTheme.successColor,
                    ),
                  ),

                  // Delete
                  IconButton(
                    onPressed: () => _confirmDelete(discount),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

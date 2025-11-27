// lib/screens/admin/discount_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/theme_config.dart';
import '../../models/discount_code.dart';
import '../../services/admin_service.dart';
import 'discount_form_screen.dart';

class DiscountDetailScreen extends StatefulWidget {
  final DiscountCode discount;

  const DiscountDetailScreen({Key? key, required this.discount})
    : super(key: key);

  @override
  State<DiscountDetailScreen> createState() => _DiscountDetailScreenState();
}

class _DiscountDetailScreenState extends State<DiscountDetailScreen> {
  late DiscountCode _discount;

  @override
  void initState() {
    super.initState();
    _discount = widget.discount;
  }

  Future<void> _toggleStatus() async {
    try {
      await AdminService.updateDiscountCode(
        discountId: _discount.id!,
        isActive: !(_discount.isActive ?? false),
      );

      setState(() {
        // Cập nhật local state
        _discount = DiscountCode(
          id: _discount.id,
          code: _discount.code,
          description: _discount.description,
          discountType: _discount.discountType,
          discountValue: _discount.discountValue,
          minOrderValue: _discount.minOrderValue,
          maxDiscountAmount: _discount.maxDiscountAmount,
          usageLimit: _discount.usageLimit,
          usedCount: _discount.usedCount,
          startDate: _discount.startDate,
          endDate: _discount.endDate,
          isActive: !(_discount.isActive ?? false),
        );
      });

      Fluttertoast.showToast(
        msg: 'Đã cập nhật trạng thái',
        backgroundColor: AppTheme.successColor,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa mã "${_discount.code}"?'),
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
        await AdminService.deleteDiscountCode(_discount.id!);
        Fluttertoast.showToast(
          msg: 'Đã xóa mã giảm giá',
          backgroundColor: AppTheme.successColor,
        );
        Navigator.pop(context, true);
      } catch (e) {
        Fluttertoast.showToast(
          msg: e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscountFormScreen(discount: _discount),
      ),
    );

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _discount.isExpired;
    final isActive = _discount.isActive ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Mã giảm giá'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _edit,
            tooltip: 'Sửa',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _delete,
            tooltip: 'Xóa',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _discount.code,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _discount.displayDiscount,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? Colors.grey
                          : isActive
                          ? AppTheme.successColor
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isExpired
                          ? 'HẾT HẠN'
                          : isActive
                          ? 'ĐANG HOẠT ĐỘNG'
                          : 'TẠM NGƯNG',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Description
                  if (_discount.description != null &&
                      _discount.description!.isNotEmpty)
                    _buildInfoCard(
                      'Mô tả',
                      _discount.description!,
                      Icons.description,
                    ),

                  // Discount Info
                  _buildInfoCard(
                    'Loại giảm giá',
                    _discount.discountType == 'percentage'
                        ? 'Phần trăm'
                        : 'Số tiền cố định',
                    Icons.percent,
                  ),

                  // Min Order Value
                  if (_discount.minOrderValue != null &&
                      _discount.minOrderValue! > 0)
                    _buildInfoCard(
                      'Đơn hàng tối thiểu',
                      '${_discount.minOrderValue!.toInt()}đ',
                      Icons.shopping_cart,
                    ),

                  // Max Discount
                  if (_discount.maxDiscountAmount != null)
                    _buildInfoCard(
                      'Giảm tối đa',
                      '${_discount.maxDiscountAmount!.toInt()}đ',
                      Icons.money_off,
                    ),

                  // Usage
                  _buildInfoCard(
                    'Lượt sử dụng',
                    _discount.usageLimit != null
                        ? '${_discount.usedCount ?? 0} / ${_discount.usageLimit}'
                        : 'Không giới hạn (${_discount.usedCount ?? 0} lượt)',
                    Icons.people,
                  ),

                  // Date Range
                  if (_discount.startDate != null || _discount.endDate != null)
                    _buildInfoCard(
                      'Thời gian áp dụng',
                      '${_discount.startDate != null ? _formatDate(_discount.startDate!) : 'Không giới hạn'} - ${_discount.endDate != null ? _formatDate(_discount.endDate!) : 'Không giới hạn'}',
                      Icons.calendar_today,
                    ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _toggleStatus,
                    icon: Icon(isActive ? Icons.pause : Icons.play_arrow),
                    label: Text(isActive ? 'TẠM NGƯNG' : 'KÍCH HOẠT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? Colors.orange
                          : AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _edit,
                    icon: const Icon(Icons.edit),
                    label: const Text('CHỈNH SỬA'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
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

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
    return '${date.day}/${date.month}/${date.year}';
  }
}

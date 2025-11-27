// lib/screens/admin/discount_form_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/theme_config.dart';
import '../../models/discount_code.dart';
import '../../services/admin_service.dart';

class DiscountFormScreen extends StatefulWidget {
  final DiscountCode? discount;

  const DiscountFormScreen({Key? key, this.discount}) : super(key: key);

  @override
  State<DiscountFormScreen> createState() => _DiscountFormScreenState();
}

class _DiscountFormScreenState extends State<DiscountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minOrderValueController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _usageLimitController = TextEditingController();

  String _discountType = 'percentage';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isLoading = false;

  bool get isEditMode => widget.discount != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _codeController.text = widget.discount!.code;
      _descriptionController.text = widget.discount!.description ?? '';
      _discountValueController.text = widget.discount!.discountValue.toString();
      _minOrderValueController.text =
          widget.discount!.minOrderValue?.toString() ?? '';
      _maxDiscountController.text =
          widget.discount!.maxDiscountAmount?.toString() ?? '';
      _usageLimitController.text =
          widget.discount!.usageLimit?.toString() ?? '';
      _discountType = widget.discount!.discountType;
      _startDate = widget.discount!.startDate;
      _endDate = widget.discount!.endDate;
      _isActive = widget.discount!.isActive ?? true;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minOrderValueController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (isEditMode) {
        await AdminService.updateDiscountCode(
          discountId: widget.discount!.id!,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          discountType: _discountType,
          discountValue: double.parse(_discountValueController.text),
          minOrderValue: _minOrderValueController.text.trim().isEmpty
              ? null
              : double.parse(_minOrderValueController.text),
          maxDiscountAmount: _maxDiscountController.text.trim().isEmpty
              ? null
              : double.parse(_maxDiscountController.text),
          usageLimit: _usageLimitController.text.trim().isEmpty
              ? null
              : int.parse(_usageLimitController.text),
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
        );
        Fluttertoast.showToast(
          msg: 'Cập nhật mã giảm giá thành công!',
          backgroundColor: AppTheme.successColor,
        );
      } else {
        await AdminService.createDiscountCode(
          code: _codeController.text.trim(),
          discountType: _discountType,
          discountValue: double.parse(_discountValueController.text),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          minOrderValue: _minOrderValueController.text.trim().isEmpty
              ? null
              : double.parse(_minOrderValueController.text),
          maxDiscountAmount: _maxDiscountController.text.trim().isEmpty
              ? null
              : double.parse(_maxDiscountController.text),
          usageLimit: _usageLimitController.text.trim().isEmpty
              ? null
              : int.parse(_usageLimitController.text),
          startDate: _startDate,
          endDate: _endDate,
        );
        Fluttertoast.showToast(
          msg: 'Tạo mã giảm giá thành công!',
          backgroundColor: AppTheme.successColor,
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Sửa Mã giảm giá' : 'Tạo Mã giảm giá'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mã giảm giá
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Mã giảm giá *',
                        prefixIcon: Icon(Icons.confirmation_number),
                        border: OutlineInputBorder(),
                        hintText: 'VD: SUMMER2024',
                      ),
                      enabled: !isEditMode, // Không cho sửa mã
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mã giảm giá';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mô tả
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Loại giảm giá
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.percent),
                          const SizedBox(width: 12),
                          const Text('Loại giảm giá:'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _discountType,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'percentage',
                                    child: Text('Phần trăm (%)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'fixed',
                                    child: Text('Số tiền cố định (đ)'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _discountType = value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Giá trị giảm
                    TextFormField(
                      controller: _discountValueController,
                      decoration: InputDecoration(
                        labelText: _discountType == 'percentage'
                            ? 'Giá trị giảm (%) *'
                            : 'Giá trị giảm (đ) *',
                        prefixIcon: Icon(
                          _discountType == 'percentage'
                              ? Icons.percent
                              : Icons.attach_money,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập giá trị giảm';
                        }
                        final val = double.tryParse(value);
                        if (val == null || val <= 0) {
                          return 'Giá trị phải lớn hơn 0';
                        }
                        if (_discountType == 'percentage' && val > 100) {
                          return 'Phần trăm không được vượt quá 100%';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Đơn hàng tối thiểu
                    TextFormField(
                      controller: _minOrderValueController,
                      decoration: const InputDecoration(
                        labelText: 'Đơn hàng tối thiểu (đ)',
                        prefixIcon: Icon(Icons.shopping_cart),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Giảm tối đa (chỉ với %)
                    if (_discountType == 'percentage')
                      TextFormField(
                        controller: _maxDiscountController,
                        decoration: const InputDecoration(
                          labelText: 'Giảm tối đa (đ)',
                          prefixIcon: Icon(Icons.money_off),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    if (_discountType == 'percentage')
                      const SizedBox(height: 16),

                    // Giới hạn sử dụng
                    TextFormField(
                      controller: _usageLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Giới hạn sử dụng',
                        prefixIcon: Icon(Icons.people),
                        border: OutlineInputBorder(),
                        hintText: 'Để trống = không giới hạn',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Ngày bắt đầu
                    ListTile(
                      title: Text(
                        _startDate == null
                            ? 'Ngày bắt đầu'
                            : 'Bắt đầu: ${_formatDate(_startDate!)}',
                      ),
                      leading: const Icon(Icons.calendar_today),
                      trailing: _startDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _startDate = null),
                            )
                          : null,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                    ),

                    // Ngày kết thúc
                    ListTile(
                      title: Text(
                        _endDate == null
                            ? 'Ngày kết thúc'
                            : 'Kết thúc: ${_formatDate(_endDate!)}',
                      ),
                      leading: const Icon(Icons.event),
                      trailing: _endDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _endDate = null),
                            )
                          : null,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                    ),

                    // Trạng thái kích hoạt
                    SwitchListTile(
                      title: const Text('Kích hoạt'),
                      subtitle: Text(
                        _isActive ? 'Đang hoạt động' : 'Tạm ngưng',
                      ),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                    const SizedBox(height: 24),

                    // Nút Submit
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isEditMode ? 'CẬP NHẬT' : 'TẠO MÃ GIẢM GIÁ',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

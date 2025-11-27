// lib/screens/admin/product_form_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qlbh/config/theme_config.dart';
import 'package:qlbh/models/product.dart';
import 'package:qlbh/models/category.dart';
import 'package:qlbh/services/admin_service.dart';
import 'package:qlbh/services/product_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // Nếu có product, là chức năng Sửa

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  // State quản lý danh mục và giá trị đã chọn
  List<Category> _categories = [];
  Category? _selectedCategory;

  // State quản lý ảnh
  File? _imageFile;
  String? _currentImageUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stockQuantity.toString();
      _currentImageUrl = widget.product!.imageUrl;
    }
  }

  // Lấy danh sách Categories
  Future<void> _fetchCategories() async {
    try {
      final categories = await ProductService.getCategories();
      setState(() {
        _categories = categories;
        if (widget.product != null) {
          // Set danh mục đã chọn khi sửa
          _selectedCategory = categories.firstWhere(
            (c) => c.id == widget.product!.categoryId,
            orElse: () => categories.first,
          );
        } else if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Lỗi tải danh mục: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // Xử lý chọn ảnh
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Cần package image_picker: flutter pub add image_picker
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _currentImageUrl = null; // Xóa URL cũ nếu chọn ảnh mới
      });
    }
  }

  // ✅ Xử lý Submit Form (Thêm hoặc Sửa)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text);
      final stock = int.parse(_stockController.text);
      final categoryId = _selectedCategory!.id!;
      final imagePath = _imageFile?.path;

      if (widget.product == null) {
        // CHỨC NĂNG THÊM MỚI
        await AdminService.createProduct(
          name: name,
          description: description,
          price: price,
          stockQuantity: stock,
          categoryId: categoryId,
          imagePath: imagePath,
        );
        Fluttertoast.showToast(
          msg: 'Thêm sản phẩm thành công!',
          backgroundColor: AppTheme.successColor,
        );
      } else {
        // CHỨC NĂNG SỬA
        await AdminService.updateProduct(
          productId: widget.product!.id!,
          name: name,
          description: description,
          price: price,
          stockQuantity: stock,
          categoryId: categoryId,
          imagePath: imagePath,
        );
        Fluttertoast.showToast(
          msg: 'Cập nhật sản phẩm thành công!',
          backgroundColor: AppTheme.successColor,
        );
      }

      if (mounted)
        Navigator.pop(context, true); // Trả về true để màn hình trước tải lại
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Thêm Sản phẩm Mới' : 'Sửa Sản phẩm',
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TRƯỜNG TÊN
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên Sản phẩm'),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),

              // TRƯỜNG MÔ TẢ
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 16),

              // TRƯỜNG GIÁ VÀ TỒN KHO
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
                      validator: (value) =>
                          value!.isEmpty ||
                              double.tryParse(value) == null ||
                              double.parse(value) <= 0
                          ? 'Giá không hợp lệ'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tồn kho'),
                      validator: (value) =>
                          value!.isEmpty ||
                              int.tryParse(value) == null ||
                              int.parse(value) < 0
                          ? 'Số lượng không hợp lệ'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // TRƯỜNG DANH MỤC
              const Text(
                'Danh mục',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _categories.map((Category cat) {
                  return DropdownMenuItem<Category>(
                    value: cat,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (Category? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Vui lòng chọn danh mục' : null,
              ),
              const SizedBox(height: 24),

              // TRƯỜNG ẢNH
              const Text(
                'Ảnh Sản phẩm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  // Hiển thị ảnh hiện tại hoặc ảnh mới chọn
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: (_imageFile != null)
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : (_currentImageUrl != null &&
                              _currentImageUrl!.isNotEmpty)
                        ? Image.network(
                            _currentImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.photo_library,
                                  color: Colors.grey,
                                ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.photo_library,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),

                  // Nút chọn ảnh
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload),
                    label: const Text('Chọn ảnh mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // NÚT SUBMIT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.product == null
                              ? 'TẠO SẢN PHẨM'
                              : 'LƯU THAY ĐỔI',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

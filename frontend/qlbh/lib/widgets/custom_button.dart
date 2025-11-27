// lib/widgets/custom_button.dart

import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class CustomButton extends StatelessWidget {
  final String text;
  // ✅ FIX: Thêm dấu ? để chấp nhận null, khắc phục lỗi argument_type_not_assignable.
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final IconData? icon;

  const CustomButton({
    Key? key,
    required this.text,
    // Đã thay đổi thành nullable
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Logic: Nếu isLoading là true thì onPressed là null, nếu không thì là giá trị được truyền vào
    // Loại finalOnPressed đã là VoidCallback? nên không gây lỗi.
    final finalOnPressed = isLoading ? null : onPressed;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isOutlined
          ? OutlinedButton(
              onPressed: finalOnPressed, // Sử dụng giá trị đã tính
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: color ?? AppTheme.primaryColor,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _buildChild(context, outlined: true),
            )
          : ElevatedButton(
              onPressed: finalOnPressed, // Sử dụng giá trị đã tính
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _buildChild(context),
            ),
    );
  }

  Widget _buildChild(BuildContext context, {bool outlined = false}) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            outlined ? color ?? AppTheme.primaryColor : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: outlined ? color ?? AppTheme.primaryColor : Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: outlined ? color ?? AppTheme.primaryColor : Colors.white,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: outlined ? color ?? AppTheme.primaryColor : Colors.white,
      ),
    );
  }
}

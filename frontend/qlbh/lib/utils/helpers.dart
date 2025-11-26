// lib/utils/helpers.dart
import 'package:intl/intl.dart';

class Helpers {
  // Format currency (VNĐ)
  static String formatCurrency(dynamic amount) {
    if (amount == null) return '0 đ';

    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return formatter.format(amount is String ? double.parse(amount) : amount);
  }

  // Format date
  static String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Format date short
  static String formatDateShort(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Get order status text
  static String getOrderStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'shipping':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  // Get payment status text
  static String getPaymentStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ thanh toán';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Đã thanh toán';
      case 'failed':
        return 'Thất bại';
      default:
        return status;
    }
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone
  static bool isValidPhone(String phone) {
    return RegExp(r'^0[0-9]{9}$').hasMatch(phone);
  }
}

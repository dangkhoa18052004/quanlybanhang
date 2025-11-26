// lib/models/discount_code.dart
class DiscountCode {
  final int? id;
  final String code;
  final String? description;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double? minOrderValue;
  final double? maxDiscountAmount;
  final int? usageLimit;
  final int? usedCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isActive;

  DiscountCode({
    this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    this.maxDiscountAmount,
    this.usageLimit,
    this.usedCount,
    this.startDate,
    this.endDate,
    this.isActive,
  });

  factory DiscountCode.fromJson(Map<String, dynamic> json) {
    return DiscountCode(
      id: json['id'],
      code: json['code'],
      description: json['description'],
      discountType: json['discount_type'],
      discountValue: _parseDouble(json['discount_value']),
      minOrderValue: json['min_order_value'] != null
          ? _parseDouble(json['min_order_value'])
          : null,
      maxDiscountAmount: json['max_discount_amount'] != null
          ? _parseDouble(json['max_discount_amount'])
          : null,
      usageLimit: json['usage_limit'],
      usedCount: json['used_count'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      isActive: json['is_active'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String get displayDiscount {
    if (discountType == 'percentage') {
      return '${discountValue.toInt()}%';
    } else {
      return '${discountValue.toInt()}đ';
    }
  }

  String get displayCondition {
    if (minOrderValue != null && minOrderValue! > 0) {
      return 'Đơn tối thiểu ${minOrderValue!.toInt()}đ';
    }
    return 'Không giới hạn';
  }

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  bool get isValid {
    if (isActive == false) return false;
    if (isExpired) return false;
    if (usageLimit != null && usedCount != null && usedCount! >= usageLimit!) {
      return false;
    }
    return true;
  }
}

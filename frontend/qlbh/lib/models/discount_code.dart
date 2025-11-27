// lib/models/discount_code.dart
class DiscountCode {
  final int? id;
  final String code;
  final String? description;
  final String discountType;
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
      id: _parseInt(json['id']),
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: json['discount_type']?.toString() ?? 'percentage',
      discountValue: _parseDouble(json['discount_value']) ?? 0.0,
      minOrderValue: _parseDouble(json['min_order_value']),
      maxDiscountAmount: _parseDouble(json['max_discount_amount']),
      usageLimit: _parseInt(json['usage_limit']),
      usedCount: _parseInt(json['used_count']),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
      isActive: json['is_active'] as bool?,
    );
  }

  // ✅ Helper methods để parse an toàn
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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

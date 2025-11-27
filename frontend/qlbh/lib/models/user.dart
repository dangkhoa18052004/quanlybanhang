// lib/models/user.dart
class User {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? address;
  final String role;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.address,
    required this.role,
    this.avatarUrl,
    required createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      address: json['address'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
      createdAt: null,
    );
  }

  get createdAt => null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'role': role,
      'avatar_url': avatarUrl,
    };
  }
}

import 'package:equatable/equatable.dart';

/// Authenticated customer. Mirrors the API user object.
class User extends Equatable {
  final int id;
  final String phone;
  final String fullName;
  final String email;
  final String userType;
  final bool isPhoneVerified;
  final String? dateJoined;

  const User({
    required this.id,
    required this.phone,
    required this.fullName,
    this.email = '',
    this.userType = 'CUSTOMER',
    this.isPhoneVerified = false,
    this.dateJoined,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      phone: (json['phone'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      userType: (json['user_type'] ?? 'CUSTOMER').toString(),
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      dateJoined: json['date_joined'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'full_name': fullName,
    'email': email,
    'user_type': userType,
    'is_phone_verified': isPhoneVerified,
    'date_joined': dateJoined,
  };

  @override
  List<Object?> get props => [
    id,
    phone,
    fullName,
    email,
    userType,
    isPhoneVerified,
  ];
}

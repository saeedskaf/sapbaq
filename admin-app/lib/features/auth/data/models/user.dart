import 'package:equatable/equatable.dart';

/// An authenticated staff user. `userType` drives which area of the app the
/// user lands in: `ADMIN` → admin area, `DRIVER` (workshop) → driver area.
class User extends Equatable {
  final int id;
  final String phone;
  final String fullName;
  final String userType;
  final bool isPhoneVerified;
  final String? dateJoined;

  const User({
    required this.id,
    required this.phone,
    required this.fullName,
    this.userType = 'CUSTOMER',
    this.isPhoneVerified = false,
    this.dateJoined,
  });

  bool get isAdmin => userType == 'ADMIN';
  bool get isDriver => userType == 'DRIVER';

  /// Whether this account is allowed in the admin/driver app at all.
  bool get isStaff => isAdmin || isDriver;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      phone: (json['phone'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      userType: (json['user_type'] ?? 'CUSTOMER').toString(),
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      dateJoined: json['date_joined'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'full_name': fullName,
    'user_type': userType,
    'is_phone_verified': isPhoneVerified,
    'date_joined': dateJoined,
  };

  @override
  List<Object?> get props => [id, phone, fullName, userType, isPhoneVerified];
}

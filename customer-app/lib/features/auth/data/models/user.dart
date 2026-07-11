import 'package:equatable/equatable.dart';

/// Authenticated customer. Mirrors the API user object.
///
/// Identity is a phone verified by OTP; the daily path is a 4-digit passcode +
/// biometrics. [phone] is null for a fresh social sign-in until the user
/// verifies a number; [profileCompleted] gates full app access (name + email +
/// verified phone); [passcodeSet] drives the "set your passcode" step.
class User extends Equatable {
  final int id;
  final String? phone;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final bool emailVerified;
  final bool profileCompleted;
  final bool passcodeSet;
  final String userType;
  final String? dateJoined;

  const User({
    required this.id,
    this.phone,
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.email = '',
    this.emailVerified = false,
    this.profileCompleted = false,
    this.passcodeSet = false,
    this.userType = 'CUSTOMER',
    this.dateJoined,
  });

  /// Display name — the name parts joined, skipping blanks. Parsing already
  /// falls back to splitting the server's `full_name`, so this stays populated
  /// even when only the combined field is sent.
  String get fullName => [firstName, middleName, lastName]
      .where((p) => p.trim().isNotEmpty)
      .join(' ')
      .trim();

  factory User.fromJson(Map<String, dynamic> json) {
    final parts = _namePartsFrom(json);
    return User(
      id: json['id'] as int,
      phone: (json['phone'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['phone'] as String),
      firstName: parts.$1,
      middleName: parts.$2,
      lastName: parts.$3,
      email: (json['email'] ?? '').toString(),
      emailVerified: json['email_verified'] as bool? ?? false,
      profileCompleted: json['profile_completed'] as bool? ?? false,
      passcodeSet: json['passcode_set'] as bool? ?? false,
      userType: (json['user_type'] ?? 'CUSTOMER').toString(),
      dateJoined: json['date_joined'] as String?,
    );
  }

  /// Prefer explicit name parts; fall back to splitting `full_name` so a display
  /// name survives even if the server only sends the combined field.
  static (String, String, String) _namePartsFrom(Map<String, dynamic> json) {
    final first = (json['first_name'] ?? '').toString();
    final middle = (json['middle_name'] ?? '').toString();
    final last = (json['last_name'] ?? '').toString();
    if (first.isNotEmpty || last.isNotEmpty) return (first, middle, last);
    final full = (json['full_name'] ?? '').toString().trim();
    if (full.isEmpty) return ('', '', '');
    final tokens = full.split(RegExp(r'\s+'));
    if (tokens.length == 1) return (tokens.first, '', '');
    return (tokens.first, tokens.sublist(1, tokens.length - 1).join(' '), tokens.last);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'first_name': firstName,
    'middle_name': middleName,
    'last_name': lastName,
    'full_name': fullName,
    'email': email,
    'email_verified': emailVerified,
    'profile_completed': profileCompleted,
    'passcode_set': passcodeSet,
    'user_type': userType,
    'date_joined': dateJoined,
  };

  @override
  List<Object?> get props => [
    id,
    phone,
    firstName,
    middleName,
    lastName,
    email,
    emailVerified,
    profileCompleted,
    passcodeSet,
    userType,
  ];
}

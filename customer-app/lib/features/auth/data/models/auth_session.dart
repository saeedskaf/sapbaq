import 'package:sapbaq/features/auth/data/models/user.dart';

/// The payload returned by every successful sign-in
/// (`{access, refresh, user, is_new, needs_profile}`).
///
/// [needsProfile] drives the first-use flow: when true the user must verify a
/// phone (if [User.phone] is null) and complete their profile before entering
/// the app.
class AuthSession {
  final String access;
  final String refresh;
  final User user;
  final bool isNew;
  final bool needsProfile;

  const AuthSession({
    required this.access,
    required this.refresh,
    required this.user,
    required this.isNew,
    required this.needsProfile,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      access: json['access'].toString(),
      refresh: json['refresh'].toString(),
      user: User.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      isNew: json['is_new'] as bool? ?? false,
      needsProfile: json['needs_profile'] as bool? ?? false,
    );
  }
}

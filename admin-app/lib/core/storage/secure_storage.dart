import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure persistence for JWT tokens and the cached user.
class SecureStorage {
  final _storage = const FlutterSecureStorage();

  static const String _kAccess = 'access_token';
  static const String _kRefresh = 'refresh_token';
  static const String _kUser = 'user_json';
  static const String _kPush = 'push_notifications_enabled';
  static const String _kGuest = 'guest_mode';

  // Tokens
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<String?> getAccessToken() => _storage.read(key: _kAccess);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);

  Future<bool> hasSession() async {
    final access = await _storage.read(key: _kAccess);
    return access != null && access.isNotEmpty;
  }

  // Cached user (stored as JSON, shape matches the API user object)
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _kUser, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null || raw.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  /// Clear tokens + user + guest flag (keeps device-level preferences like
  /// push opt-in).
  Future<void> clearAuthData() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
    await _storage.delete(key: _kGuest);
  }

  // Guest mode: the user chose to browse without an account. Persisted so the
  // app reopens straight into guest mode instead of the login wall.
  Future<void> setGuest(bool value) async {
    if (value) {
      await _storage.write(key: _kGuest, value: 'true');
    } else {
      await _storage.delete(key: _kGuest);
    }
  }

  Future<bool> isGuest() async =>
      (await _storage.read(key: _kGuest)) == 'true';

  Future<void> deleteAll() => _storage.deleteAll();

  // Push preference (used by the notifications feature later)
  Future<void> savePushEnabled(bool enabled) =>
      _storage.write(key: _kPush, value: enabled.toString());

  Future<bool> getPushEnabled() async =>
      (await _storage.read(key: _kPush)) != 'false';
}

final secureStorage = SecureStorage();

import 'package:dio/dio.dart';
import 'package:sapbaq_admin/core/network/api_endpoints.dart';
import 'package:sapbaq_admin/core/network/api_guard.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/core/storage/secure_storage.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';

/// Single source of truth for staff authentication (the seven staff roles).
///
/// All methods throw [ApiException] (Arabic, display-ready) on failure. Session
/// transitions are published through [SessionManager], which the router and
/// AuthBloc observe. Accounts are provisioned on the backend — there is no
/// self-signup or guest mode in this app.
class AuthRepository {
  final Dio _dio;
  final SecureStorage _storage;
  final SessionManager _session;

  AuthRepository({
    required Dio dio,
    required SecureStorage storage,
    required SessionManager session,
  })  : _dio = dio,
        _storage = storage,
        _session = session;

  Stream<AuthStatus> get status => _session.stream;
  AuthStatus get currentStatus => _session.status;

  /// Resolve the initial session at startup: a stored token → authenticated,
  /// else unauthenticated.
  Future<void> bootstrap() async {
    if (await _storage.hasSession()) {
      _session.setStatus(AuthStatus.authenticated);
    } else {
      _session.setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<User?> cachedUser() async {
    final json = await _storage.getUser();
    return json == null ? null : User.fromJson(json);
  }

  Future<void> login({required String phone, required String password}) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {'phone': phone, 'password': password},
      );
      await _persistSession(res.data);
    });
  }

  /// Fetch the current user and refresh the cache (e.g. to confirm `user_type`
  /// right after login or on resume).
  Future<User> getMe() {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.me);
      final user = User.fromJson(Map<String, dynamic>.from(res.data as Map));
      await _storage.saveUser(user.toJson());
      return user;
    });
  }

  Future<void> logout() async {
    await _storage.clearAuthData();
    _session.unauthenticated();
  }

  // --- helpers ---

  Future<void> _persistSession(dynamic data) async {
    final map = Map<String, dynamic>.from(data as Map);
    await _storage.saveTokens(
      access: map['access'].toString(),
      refresh: map['refresh'].toString(),
    );
    if (map['user'] is Map) {
      await _storage.saveUser(Map<String, dynamic>.from(map['user'] as Map));
    }
    _session.authenticated();
  }

  Future<T> _guard<T>(Future<T> Function() request) => guardApi(request);
}

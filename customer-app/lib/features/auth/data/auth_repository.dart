import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/storage/secure_storage.dart';
import 'package:sapbaq/features/auth/data/models/user.dart';

/// Single source of truth for authentication.
///
/// All methods throw [ApiException] (Arabic, display-ready) on failure. Session
/// transitions are published through [SessionManager], which the router and
/// AuthBloc observe.
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
  /// else a persisted guest choice → guest, else unauthenticated.
  Future<void> bootstrap() async {
    if (await _storage.hasSession()) {
      _session.setStatus(AuthStatus.authenticated);
    } else if (await _storage.isGuest()) {
      _session.setStatus(AuthStatus.guest);
    } else {
      _session.setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Enter guest (browse-only) mode — no account. Persisted so the app reopens
  /// in guest mode until the user logs in or out.
  Future<void> enterGuest() async {
    await _storage.setGuest(true);
    _session.guest();
  }

  Future<User?> cachedUser() async {
    final json = await _storage.getUser();
    return json == null ? null : User.fromJson(json);
  }

  /// Create an account; the backend sends a verification OTP over SMS. Throws
  /// [ApiException] on failure (e.g. the phone is already registered).
  Future<void> signup({
    required String phone,
    required String fullName,
    required String password,
  }) {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.signup,
        data: {'phone': phone, 'full_name': fullName, 'password': password},
      );
    });
  }

  Future<void> verifyOtp({required String phone, required String code}) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {'phone': phone, 'code': code},
      );
      await _persistSession(res.data);
    });
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

  /// Request a password-reset OTP, sent to the phone over SMS.
  Future<void> forgotPassword({required String phone}) {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'phone': phone},
      );
    });
  }

  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.resetPassword,
        data: {'phone': phone, 'code': code, 'new_password': newPassword},
      );
      await _persistSession(res.data);
    });
  }

  Future<User> getMe() {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.me);
      final user = User.fromJson(Map<String, dynamic>.from(res.data as Map));
      await _storage.saveUser(user.toJson());
      return user;
    });
  }

  /// Update the current user's profile. [fullName] and [email] are editable
  /// server-side (`phone` and `user_type` are read-only); pass only the fields
  /// you want to change. Persists and returns the fresh user.
  Future<User> updateProfile({String? fullName, String? email}) {
    return _guard(() async {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (email != null) data['email'] = email;
      final res = await _dio.patch(ApiEndpoints.me, data: data);
      final user = User.fromJson(Map<String, dynamic>.from(res.data as Map));
      await _storage.saveUser(user.toJson());
      return user;
    });
  }

  Future<void> logout() async {
    await _storage.clearAuthData();
    _session.unauthenticated();
  }

  /// Permanently delete (anonymize) the current user's account, then clear the
  /// local session (which redirects to login). [password] is required by the
  /// backend as a second confirmation on top of the JWT. On a wrong password
  /// the thrown [ApiException] carries `fieldError('password')`.
  Future<void> deleteAccount({required String password}) async {
    await _guard(() async {
      await _dio.delete(ApiEndpoints.me, data: {'password': password});
    });
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
    await _storage.setGuest(false); // logging in supersedes guest mode
    _session.authenticated();
  }

  Future<T> _guard<T>(Future<T> Function() request) => guardApi(request);
}

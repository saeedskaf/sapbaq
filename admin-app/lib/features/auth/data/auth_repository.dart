import 'package:dio/dio.dart';
import 'package:sapbaq_admin/core/network/api_endpoints.dart';
import 'package:sapbaq_admin/core/network/api_guard.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/core/storage/secure_storage.dart';
import 'package:sapbaq_admin/features/auth/data/models/otp_send_meta.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';
import 'package:sapbaq_admin/features/rep/data/models/rep_models.dart';

/// Single source of truth for authentication: the staff roles (backend-
/// provisioned phone+password) and the mosque representative (`/rep/*` —
/// phone + OTP + 4-digit passcode, self-registered).
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
  }) : _dio = dio,
       _storage = storage,
       _session = session;

  Stream<AuthStatus> get status => _session.stream;
  AuthStatus get currentStatus => _session.status;

  /// Runs at the very start of [logout], while the access token is still valid,
  /// so the push service can unregister this device's FCM token without hitting
  /// a 401 (see FLUTTER_FCM_DEVICE_UNREGISTER_NOTE.md). Wired in `main()`.
  Future<void> Function()? onBeforeLogout;

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
  /// right after login or on resume). Role-aware: a mosque representative is
  /// served by `/rep/me/` (staff `/auth/me/` is not his endpoint).
  Future<User> getMe() {
    return _guard(() async {
      final cached = await cachedUser();
      if (cached != null && cached.userType == User.mosqueRep) {
        final res = await _dio.get(ApiEndpoints.repMe);
        final profile = RepProfile.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
        final user = _userFromRep(profile);
        await _storage.saveUser(user.toJson());
        return user;
      }
      final res = await _dio.get(ApiEndpoints.me);
      final user = User.fromJson(Map<String, dynamic>.from(res.data as Map));
      await _storage.saveUser(user.toJson());
      return user;
    });
  }

  Future<void> logout() async {
    // Unregister the FCM device *before* dropping tokens — the DELETE is
    // authenticated, so it must go out while the Bearer is still valid.
    try {
      await onBeforeLogout?.call();
    } catch (_) {
      // Best-effort; never block sign-out on a notification cleanup failure.
    }
    await _storage.clearAuthData();
    _session.unauthenticated();
  }

  // --- Mosque representative (`/rep/*` — ADMIN_APP_BACKEND_INTEGRATION §1) ---

  /// Send (or resend) the rep OTP. Returns the server's resend cooldown
  /// ([OtpSendMeta.resendAvailableIn]) — same contract as the customer app.
  Future<OtpSendMeta> repRequestOtp(String phone) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.repOtpRequest,
        data: {'phone': phone},
      );
      return OtpSendMeta.fromJson(res.data);
    });
  }

  /// Self-registration → PENDING (no token). The rep waits for Sapbaq approval
  /// before he can log in.
  Future<void> repRegister({
    required String phone,
    required String code,
    required String firstName,
    required String lastName,
    required int mosqueId,
    required String passcode,
  }) {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.repRegister,
        data: {
          'phone': phone,
          'code': code,
          'first_name': firstName,
          'last_name': lastName,
          'mosque_id': mosqueId,
          'passcode': passcode,
        },
      );
    });
  }

  /// Look up the mosque an invite token is pre-bound to.
  Future<RepInviteInfo> repInviteInfo(String token) {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.repInvite(token));
      return RepInviteInfo.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  /// Invite registration → ACTIVE immediately, with a session.
  Future<void> repRegisterInvite({
    required String token,
    required String phone,
    required String code,
    required String passcode,
    String? firstName,
    String? lastName,
  }) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.repRegisterInvite,
        data: {
          'token': token,
          'phone': phone,
          'code': code,
          'passcode': passcode,
          if (firstName != null && firstName.isNotEmpty)
            'first_name': firstName,
          if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        },
      );
      await _persistRepSession(res.data);
    });
  }

  /// Daily rep login. A PENDING/DEACTIVATED account is rejected by the server
  /// with a display-ready Arabic message.
  Future<void> repLogin({required String phone, required String passcode}) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.repLogin,
        data: {'phone': phone, 'passcode': passcode},
      );
      await _persistRepSession(res.data);
    });
  }

  Future<void> repResetPasscode({
    required String phone,
    required String code,
    required String passcode,
  }) {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.repResetPasscode,
        data: {'phone': phone, 'code': code, 'passcode': passcode},
      );
    });
  }

  /// Persist a rep session. The user cache must carry `user_type: MOSQUE_REP`
  /// so the router lands on the rep shell — synthesized from the response (or
  /// `/rep/me/`) since rep payloads are profile-shaped, not staff-shaped.
  Future<void> _persistRepSession(dynamic data) async {
    final map = Map<String, dynamic>.from(data as Map);
    await _storage.saveTokens(
      access: map['access'].toString(),
      refresh: (map['refresh'] ?? '').toString(),
    );
    RepProfile? profile;
    final userJson = map['user'] ?? map['rep'] ?? map['profile'];
    if (userJson is Map) {
      profile = RepProfile.fromJson(Map<String, dynamic>.from(userJson));
    } else {
      try {
        final res = await _dio.get(ApiEndpoints.repMe);
        profile = RepProfile.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
      } catch (_) {
        // Tokens are in — a minimal cache below still routes correctly.
      }
    }
    final user = profile != null
        ? _userFromRep(profile)
        : const User(id: 0, phone: '', fullName: '', userType: User.mosqueRep);
    await _storage.saveUser(user.toJson());
    _session.authenticated();
  }

  User _userFromRep(RepProfile profile) => User(
    id: profile.id,
    phone: profile.phone,
    fullName: profile.fullName,
    userType: User.mosqueRep,
  );

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

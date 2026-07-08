import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sapbaq/core/config/environment.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/storage/secure_storage.dart';
import 'package:sapbaq/features/auth/data/models/auth_session.dart';
import 'package:sapbaq/features/auth/data/models/passkey_device.dart';
import 'package:sapbaq/features/auth/data/models/user.dart';
import 'package:sapbaq/features/auth/data/passkey_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Single source of truth for authentication.
///
/// The customer account is **passwordless**: sign in with Google, Apple, or a
/// phone OTP. Every successful sign-in yields an [AuthSession]; when
/// `needsProfile` is set the session goes to [AuthStatus.completingProfile]
/// (verify a phone if missing, then complete the profile) before the app opens.
///
/// All network methods throw [ApiException] (Arabic, display-ready) on failure.
/// The social methods return `null` when the user cancels the native sheet, so
/// callers can quietly reset instead of showing an error.
class AuthRepository {
  final Dio _dio;
  final SecureStorage _storage;
  final SessionManager _session;
  final GoogleSignIn _googleSignIn;
  final PasskeyService _passkey;

  AuthRepository({
    required Dio dio,
    required SecureStorage storage,
    required SessionManager session,
    GoogleSignIn? googleSignIn,
    PasskeyService? passkeyService,
  })  : _dio = dio,
        _storage = storage,
        _session = session,
        _passkey = passkeyService ?? PasskeyService(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: Environment.googleServerClientId,
              scopes: const ['email', 'profile'],
            );

  Stream<AuthStatus> get status => _session.stream;
  AuthStatus get currentStatus => _session.status;

  /// Resolve the initial session at startup: a stored token → authenticated (or
  /// completing-profile if the cached user hasn't finished onboarding), else a
  /// persisted guest choice → guest, else unauthenticated.
  Future<void> bootstrap() async {
    if (await _storage.hasSession()) {
      final user = await cachedUser();
      _session.setStatus(
        user != null && !user.profileCompleted
            ? AuthStatus.completingProfile
            : AuthStatus.authenticated,
      );
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

  // ── Phone OTP ──────────────────────────────────────────────────────────────

  /// Send a login OTP to [phone] over SMS.
  Future<void> requestOtp({required String phone}) {
    return _guard(() async {
      await _dio.post(ApiEndpoints.otpRequest, data: {'phone': phone});
    });
  }

  /// Verify a login OTP → session. A phone user has a verified phone already, so
  /// `needsProfile` (if set) means only name/email are outstanding.
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
  }) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.otpVerify,
        data: {'phone': phone, 'code': code},
      );
      return _persistSession(res.data);
    });
  }

  // ── Social ───────────────────────────────────────────────────────────────

  /// Google sign-in. Returns `null` if the user dismisses the account picker.
  Future<AuthSession?> signInWithGoogle() async {
    GoogleSignInAccount? account;
    try {
      // Sign out first so the account chooser always appears (rather than
      // silently reusing the last account).
      await _googleSignIn.signOut();
      account = await _googleSignIn.signIn();
    } catch (_) {
      // Platform/config errors surface as a generic failure below.
      account = null;
    }
    if (account == null) return null; // cancelled

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) return null;
    final (first, last) = _splitName(account.displayName);

    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.socialGoogle,
        data: {
          'id_token': idToken,
          if (first.isNotEmpty) 'first_name': first,
          if (last.isNotEmpty) 'last_name': last,
        },
      );
      return _persistSession(res.data);
    });
  }

  /// Apple sign-in. Apple returns the name only on the *first* authorization, so
  /// forward it when present. Returns `null` if the user cancels.
  Future<AuthSession?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: _sha256(rawNonce),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      debugPrint('Apple sign-in authorization error: ${e.code} — ${e.message}');
      throw _appleError();
    } catch (e, st) {
      // e.g. SignInWithAppleNotSupportedException, PlatformException, etc.
      debugPrint('Apple sign-in failed: $e\n$st');
      throw _appleError();
    }

    final identityToken = credential.identityToken;
    if (identityToken == null) return null;
    final firstName = credential.givenName;
    final lastName = credential.familyName;

    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.socialApple,
        data: {
          'identity_token': identityToken,
          'nonce': rawNonce,
          if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
          if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        },
      );
      return _persistSession(res.data);
    });
  }

  // ── Phone verification (during profile completion, authenticated) ──────────

  /// Send a verification OTP to [phone] for a social user who has no phone yet.
  Future<void> requestPhone({required String phone}) {
    return _guard(() async {
      await _dio.post(ApiEndpoints.phoneRequest, data: {'phone': phone});
    });
  }

  /// Confirm the phone OTP. Returns the updated user (now with a verified
  /// phone); the session stays in completing-profile until [completeProfile].
  Future<User> verifyPhone({required String phone, required String code}) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.phoneVerify,
        data: {'phone': phone, 'code': code},
      );
      return _saveUser(res.data);
    });
  }

  // ── Profile completion ─────────────────────────────────────────────────────

  /// Finish onboarding. The backend rejects this (400) unless a verified phone
  /// exists. On success the session becomes authenticated.
  Future<User> completeProfile({
    required String firstName,
    required String lastName,
    String? middleName,
    required String email,
  }) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.profileComplete,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          if (middleName != null && middleName.isNotEmpty)
            'middle_name': middleName,
          'email': email,
        },
      );
      final user = await _saveUser(res.data);
      _session.authenticated();
      return user;
    });
  }

  // ── Account (authenticated) ────────────────────────────────────────────────

  Future<User> getMe() {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.me);
      return _saveUser(res.data);
    });
  }

  /// Update the current user's profile. Pass only the fields to change; `phone`
  /// and `user_type` are read-only server-side. Persists and returns the user.
  Future<User> updateProfile({
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
  }) {
    return _guard(() async {
      final data = <String, dynamic>{
        'first_name': ?firstName,
        'middle_name': ?middleName,
        'last_name': ?lastName,
        'email': ?email,
      };
      final res = await _dio.patch(ApiEndpoints.me, data: data);
      return _saveUser(res.data);
    });
  }

  Future<void> logout() async {
    // Drop tokens locally; the Google session is cleared so the next sign-in
    // shows the chooser. Any device passkey is intentionally left in place.
    await _storage.clearAuthData();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _session.unauthenticated();
  }

  /// Passwordless deletion needs a fresh OTP: request one to the user's phone
  /// first, then call [deleteAccount] with the code.
  Future<void> requestDeleteOtp() {
    return _guard(() async {
      final user = await cachedUser();
      final phone = user?.phone;
      if (phone == null || phone.isEmpty) {
        throw DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.otpRequest),
        );
      }
      await _dio.post(ApiEndpoints.otpRequest, data: {'phone': phone});
    });
  }

  /// Permanently delete (anonymize) the account with an OTP [code], then clear
  /// the local session (which redirects to login).
  Future<void> deleteAccount({required String code}) async {
    await _guard(() async {
      await _dio.delete(ApiEndpoints.me, data: {'code': code});
    });
    await _storage.clearAuthData();
    _session.unauthenticated();
  }

  // ── Passkeys (WebAuthn) ─────────────────────────────────────────────────────

  /// Whether this device can create/use passkeys (gates the passkey UI).
  Future<bool> passkeysSupported() => _passkey.isSupported();

  /// Register a passkey for the signed-in user. Returns `false` if the user
  /// dismisses the native sheet; throws [PasskeyException] on platform failure.
  Future<bool> registerPasskey({String? deviceName}) async {
    final begin = await _guard(() async {
      final res = await _dio.post(ApiEndpoints.passkeyRegisterBegin);
      return Map<String, dynamic>.from(res.data as Map);
    });
    final credential = await _passkey.register(
      Map<String, dynamic>.from(begin['options'] as Map),
    );
    if (credential == null) return false; // cancelled
    await _guard(() async {
      await _dio.post(
        ApiEndpoints.passkeyRegisterComplete,
        data: {
          'handle': begin['handle'],
          'credential': credential,
          if (deviceName != null && deviceName.isNotEmpty)
            'device_name': deviceName,
        },
      );
    });
    return true;
  }

  /// Sign in with a device passkey (discoverable — no phone/email needed).
  /// Returns the session, or `null` if the user cancels.
  Future<AuthSession?> loginWithPasskey() async {
    final begin = await _guard(() async {
      final res = await _dio.post(ApiEndpoints.passkeyLoginBegin);
      return Map<String, dynamic>.from(res.data as Map);
    });
    final credential = await _passkey.authenticate(
      Map<String, dynamic>.from(begin['options'] as Map),
    );
    if (credential == null) return null; // cancelled
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.passkeyLoginComplete,
        data: {'handle': begin['handle'], 'credential': credential},
      );
      return _persistSession(res.data);
    });
  }

  Future<List<PasskeyDevice>> listPasskeys() {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.passkeyDevices);
      final list = res.data as List;
      return list
          .map((e) => PasskeyDevice.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  Future<void> deletePasskey(int id) {
    return _guard(() async {
      await _dio.delete(ApiEndpoints.passkeyDevice(id));
    });
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Persist tokens + user from a session payload and publish the resulting
  /// status (completing-profile when the backend flags `needs_profile`).
  Future<AuthSession> _persistSession(dynamic data) async {
    final session = AuthSession.fromJson(Map<String, dynamic>.from(data as Map));
    await _storage.saveTokens(access: session.access, refresh: session.refresh);
    await _storage.saveUser(session.user.toJson());
    await _storage.setGuest(false); // signing in supersedes guest mode
    if (session.needsProfile) {
      _session.completingProfile();
    } else {
      _session.authenticated();
    }
    return session;
  }

  Future<User> _saveUser(dynamic data) async {
    final user = User.fromJson(Map<String, dynamic>.from(data as Map));
    await _storage.saveUser(user.toJson());
    return user;
  }

  (String, String) _splitName(String? displayName) {
    final name = (displayName ?? '').trim();
    if (name.isEmpty) return ('', '');
    final tokens = name.split(RegExp(r'\s+'));
    if (tokens.length == 1) return (tokens.first, '');
    return (tokens.first, tokens.sublist(1).join(' '));
  }

  String _generateNonce([int length = 32]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => charset[rand.nextInt(charset.length)],
    ).join();
  }

  String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  ApiException _appleError() => const ApiException(
        statusCode: 0,
        code: 'apple_signin',
        message: 'تعذّر تسجيل الدخول عبر Apple. حاول مرة أخرى.',
      );

  Future<T> _guard<T>(Future<T> Function() request) => guardApi(request);
}

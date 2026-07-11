import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sapbaq/core/auth/biometric_service.dart';
import 'package:sapbaq/core/config/environment.dart';
import 'package:sapbaq/core/device/device_identity.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/storage/secure_storage.dart';
import 'package:sapbaq/features/auth/data/models/auth_session.dart';
import 'package:sapbaq/features/auth/data/models/passkey_device.dart';
import 'package:sapbaq/features/auth/data/models/trusted_device.dart';
import 'package:sapbaq/features/auth/data/models/user.dart';
import 'package:sapbaq/features/auth/data/passkey_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Outcome of `otp/check-number/`: drives the one-screen/two-outcomes login.
class NumberStatus {
  final bool registered;
  final bool passcodeSet;
  const NumberStatus({required this.registered, required this.passcodeSet});
}

/// Single source of truth for authentication (Sapbaq_AUTH_Flow).
///
/// Identity is a phone verified by OTP. The daily path is a **4-digit passcode**
/// plus a **local biometric unlock**; OTP is used only for first verification,
/// new-device trust, and passcode recovery. Google/Apple are alternative entry
/// points that still resolve to a verified phone.
///
/// Every successful sign-in yields an [AuthSession]; `needsProfile` routes to
/// [AuthStatus.completingProfile], a missing passcode to
/// [AuthStatus.settingPasscode], and a persisted-but-unopened session to
/// [AuthStatus.locked].
///
/// All network methods throw [ApiException] (display-ready) on failure. Social
/// methods return `null` when the user cancels the native sheet.
class AuthRepository {
  final Dio _dio;
  final SecureStorage _storage;
  final SessionManager _session;
  final GoogleSignIn _googleSignIn;
  final PasskeyService _passkey;
  final DeviceIdentity _device;
  final BiometricService _biometric;

  AuthRepository({
    required Dio dio,
    required SecureStorage storage,
    required SessionManager session,
    GoogleSignIn? googleSignIn,
    PasskeyService? passkeyService,
    DeviceIdentity? deviceIdentity,
    BiometricService? biometricService,
  })  : _dio = dio,
        _storage = storage,
        _session = session,
        _passkey = passkeyService ?? PasskeyService(),
        _device = deviceIdentity ?? DeviceIdentity(storage: storage),
        _biometric = biometricService ?? BiometricService(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: Environment.googleServerClientId,
              scopes: const ['email', 'profile'],
            );

  Stream<AuthStatus> get status => _session.stream;
  AuthStatus get currentStatus => _session.status;

  /// Resolve the initial session at startup. A stored token is *not* enough to
  /// open the app: an unfinished account routes to onboarding, a set-up account
  /// starts [AuthStatus.locked] so it must be unlocked (biometric or passcode)
  /// on every cold launch — the local gate the long-lived session relies on.
  Future<void> bootstrap() async {
    if (await _storage.hasSession()) {
      final user = await cachedUser();
      if (user == null || !user.profileCompleted) {
        _session.setStatus(AuthStatus.completingProfile);
      } else if (!user.passcodeSet) {
        _session.setStatus(AuthStatus.settingPasscode);
      } else {
        _session.setStatus(AuthStatus.locked);
      }
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

  // ── Phone OTP / number check ────────────────────────────────────────────────

  /// Ask the server whether [phone] is registered and has a passcode — the
  /// single decision that splits the login screen into sign-in vs sign-up.
  /// Sends no OTP and never reveals staff accounts.
  Future<NumberStatus> checkNumber({required String phone}) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.otpCheckNumber,
        data: {'phone': phone},
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return NumberStatus(
        registered: data['registered'] as bool? ?? false,
        passcodeSet: data['passcode_set'] as bool? ?? false,
      );
    });
  }

  /// Send a verification OTP to [phone] over SMS (sign-up / device trust flows).
  Future<void> requestOtp({required String phone}) {
    return _guard(() async {
      await _dio.post(ApiEndpoints.otpRequest, data: {'phone': phone});
    });
  }

  /// Verify an OTP → session. Passing this device's id auto-trusts it (first
  /// verification), so future logins on it need only the passcode.
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
  }) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.otpVerify,
        data: {
          'phone': phone,
          'code': code,
          'device_id': await _device.deviceId(),
          'device_name': await _device.deviceName(),
        },
      );
      return _persistSession(res.data);
    });
  }

  // ── Passcode (daily login) ──────────────────────────────────────────────────

  /// Day-to-day sign-in on a trusted device — no OTP. Throws [ApiException]
  /// with `statusCode` 428 (device untrusted → run device trust) or 423
  /// (passcode locked → run forgot-passcode); a wrong code < 5 attempts is 400.
  Future<AuthSession> passcodeLogin({
    required String phone,
    required String passcode,
  }) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.passcodeLogin,
        data: {
          'phone': phone,
          'passcode': passcode,
          'device_id': await _device.deviceId(),
        },
      );
      return _persistSession(res.data);
    });
  }

  /// Set the 4-digit passcode for the signed-in user (end of onboarding).
  Future<User> setPasscode({required String passcode}) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.passcodeSet,
        data: {'passcode': passcode, 'passcode_confirm': passcode},
      );
      return _saveUser(res.data);
    });
  }

  /// Send a recovery OTP for a forgotten/locked passcode.
  Future<void> forgotPasscodeRequest({required String phone}) {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.passcodeForgotRequest,
        data: {'phone': phone},
      );
    });
  }

  /// Reset the passcode with a recovery OTP → session (also re-trusts this
  /// device, since an OTP was completed).
  Future<AuthSession> forgotPasscodeReset({
    required String phone,
    required String code,
    required String newPasscode,
  }) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.passcodeForgotReset,
        data: {
          'phone': phone,
          'code': code,
          'new_passcode': newPasscode,
          'new_passcode_confirm': newPasscode,
          'device_id': await _device.deviceId(),
        },
      );
      return _persistSession(res.data);
    });
  }

  // ── Device trust (new / reinstalled device) ─────────────────────────────────

  /// Send an OTP to establish trust for this device.
  Future<void> deviceTrustRequest({required String phone}) {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.deviceTrustRequest,
        data: {'phone': phone},
      );
    });
  }

  /// Confirm the OTP and trust this device. Issues no session — the caller then
  /// retries [passcodeLogin], which now succeeds.
  Future<void> deviceTrustVerify({
    required String phone,
    required String code,
  }) {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.deviceTrustVerify,
        data: {
          'phone': phone,
          'code': code,
          'device_id': await _device.deviceId(),
          'device_name': await _device.deviceName(),
        },
      );
    });
  }

  // ── Trusted-device management ───────────────────────────────────────────────

  /// The user's trusted devices. Passing this device's id lets the backend flag
  /// the `current` entry.
  Future<List<TrustedDevice>> listTrustedDevices() {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.deviceTrusted,
        queryParameters: {'device_id': await _device.deviceId()},
      );
      final list = res.data as List;
      return list
          .map((e) =>
              TrustedDevice.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  /// Revoke trust for a device — it will need a fresh OTP on its next sign-in.
  Future<void> revokeTrustedDevice(int id) {
    return _guard(() async {
      await _dio.delete(ApiEndpoints.deviceTrustedItem(id));
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

  /// Confirm the phone OTP for a social user. Passing this device's id trusts it
  /// (an OTP was completed). Returns the updated user (now with a verified
  /// phone); the session stays in completing-profile until [completeProfile].
  Future<User> verifyPhone({required String phone, required String code}) {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.phoneVerify,
        data: {
          'phone': phone,
          'code': code,
          'device_id': await _device.deviceId(),
          'device_name': await _device.deviceName(),
        },
      );
      await _storage.saveRememberedPhone(phone);
      return _saveUser(res.data);
    });
  }

  // ── Profile completion ─────────────────────────────────────────────────────

  /// Finish the name/email step. The backend rejects this (400) unless a
  /// verified phone exists. Advances to the passcode step (or, defensively,
  /// straight in if the account already has one).
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
      if (user.passcodeSet) {
        _session.authenticated();
      } else {
        _session.settingPasscode();
      }
      return user;
    });
  }

  /// Finish onboarding after the passcode (and optional biometric opt-in) are
  /// set — opens the app.
  void completePasscodeSetup() => _session.authenticated();

  // ── Biometric unlock + lock gate ────────────────────────────────────────────

  /// Whether this device can offer Face ID / Touch ID unlock.
  Future<bool> biometricAvailable() => _biometric.isAvailable();

  Future<bool> biometricEnabled() => _storage.getBiometricEnabled();

  Future<void> setBiometricEnabled(bool value) =>
      _storage.setBiometricEnabled(value);

  /// Unlock a persisted session with biometrics (no network). On success flips
  /// [AuthStatus.locked] → authenticated; on cancel/failure returns false so the
  /// caller falls back to the passcode.
  Future<bool> unlockWithBiometrics({required String reason}) async {
    final ok = await _biometric.authenticate(reason: reason);
    if (ok) _session.authenticated();
    return ok;
  }

  // ── Account (authenticated) ────────────────────────────────────────────────

  Future<User> getMe() {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.me);
      return _saveUser(res.data);
    });
  }

  // Name/email are not editable by the customer (Sapbaq_AUTH_Flow §12) — staff
  // edit them from the dashboard, so there is no client update method.

  /// The last number that signed in on this device (pre-filled on login).
  Future<String?> rememberedPhone() => _storage.getRememberedPhone();

  /// "Not me?" — forget the remembered number so a different person can sign in.
  Future<void> forgetRememberedPhone() => _storage.clearRememberedPhone();

  Future<void> logout() async {
    // Drop tokens locally and turn off biometric unlock (nothing to unlock once
    // signed out). Device trust (device_id) and the remembered number are kept
    // so the next sign-in needs only the passcode, not a fresh OTP.
    await _storage.clearAuthData();
    await _storage.setBiometricEnabled(false);
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
    final phone = session.user.phone;
    if (phone != null && phone.isNotEmpty) {
      await _storage.saveRememberedPhone(phone);
    }
    if (session.needsProfile) {
      _session.completingProfile();
    } else if (!session.user.passcodeSet) {
      // e.g. a legacy account with no passcode yet.
      _session.settingPasscode();
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

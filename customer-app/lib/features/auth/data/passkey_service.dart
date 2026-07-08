import 'package:flutter/foundation.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

/// Why a passkey ceremony failed (mapped to a message in the UI layer).
enum PasskeyFailure { notSupported, noCredentials, unknown }

class PasskeyException implements Exception {
  final PasskeyFailure reason;
  PasskeyException(this.reason);
}

/// Bridges the platform authenticator (Face ID / fingerprint / device PIN) for
/// WebAuthn ceremonies. The server drives the challenge; this only translates
/// its options JSON into a native prompt and returns the result JSON.
///
/// Both [register] and [authenticate] return `null` when the user dismisses the
/// native sheet, and throw [PasskeyException] for genuine platform failures.
class PasskeyService {
  final PasskeyAuthenticator _authenticator;

  PasskeyService({PasskeyAuthenticator? authenticator})
      : _authenticator = authenticator ?? PasskeyAuthenticator();

  /// Whether this device can create/use passkeys at all.
  Future<bool> isSupported() async {
    try {
      // ignore: deprecated_member_use
      return await _authenticator.canAuthenticate();
    } catch (_) {
      return false;
    }
  }

  /// Create a passkey from server creation `options`; returns the attestation
  /// credential JSON to send back to the server.
  Future<Map<String, dynamic>?> register(Map<String, dynamic> options) {
    return _run(
      () async =>
          (await _authenticator.register(RegisterRequestType.fromJson(options)))
              .toJson(),
    );
  }

  /// Assert an existing passkey from server request `options`; returns the
  /// assertion credential JSON to send back to the server.
  Future<Map<String, dynamic>?> authenticate(Map<String, dynamic> options) {
    return _run(
      () async => (await _authenticator.authenticate(
        AuthenticateRequestType.fromJson(
          options,
          mediation: MediationType.Optional,
          preferImmediatelyAvailableCredentials: false,
        ),
      )).toJson(),
    );
  }

  Future<Map<String, dynamic>?> _run(
    Future<Map<String, dynamic>> Function() op,
  ) async {
    try {
      return await op();
    } on PasskeyAuthCancelledException {
      return null; // user dismissed the native sheet
    } on NoCredentialsAvailableException {
      throw PasskeyException(PasskeyFailure.noCredentials);
    } on DeviceNotSupportedException {
      throw PasskeyException(PasskeyFailure.notSupported);
    } on PasskeyUnsupportedException {
      throw PasskeyException(PasskeyFailure.notSupported);
    } on AuthenticatorException catch (e) {
      // Domain-not-associated, sync-account-missing, timeout, etc. all land
      // here — log the concrete type so config issues can be diagnosed.
      debugPrint('Passkey ceremony failed (authenticator): $e');
      throw PasskeyException(PasskeyFailure.unknown);
    } catch (e, st) {
      // Malformed server options (FormatException/TypeError) or anything else.
      debugPrint('Passkey ceremony failed: $e\n$st');
      throw PasskeyException(PasskeyFailure.unknown);
    }
  }
}

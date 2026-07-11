import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Local Face ID / Touch ID gate.
///
/// This is a **local unlock**, not a server credential: a successful prompt
/// only releases the session already stored on this device. The 4-digit
/// passcode (server-verified, lockout-protected) is always the fallback, so a
/// device that can't or won't use biometrics loses no capability.
///
/// Note on enrolment changes: hard binding to the current biometric set (so a
/// newly-added fingerprint is rejected) needs platform keychain access control,
/// which `flutter_secure_storage` 9.x does not expose. The residual risk is
/// bounded because biometrics only unlock an existing on-device session and the
/// server passcode is still required after logout.
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// Whether the device has hardware and at least one enrolled biometric, so
  /// the "enable Face ID / Touch ID" option is worth offering.
  Future<bool> isAvailable() async {
    try {
      final supported =
          await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
      if (!supported) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (e) {
      debugPrint('BiometricService.isAvailable failed: $e');
      return false;
    }
  }

  /// Prompt for biometrics. Returns `true` on success, `false` when the user
  /// cancels or the platform can't authenticate — callers then fall back to the
  /// passcode rather than surfacing an error.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricService.authenticate error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('BiometricService.authenticate failed: $e');
      return false;
    }
  }
}

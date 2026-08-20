import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists "when the next OTP resend is allowed", keyed by purpose+phone, so
/// the countdown survives leaving/returning to the screen and app restarts. The
/// wait is server-authoritative (Sapbaq_AUTH_Flow: escalating 30→60→120→300);
/// callers just record the seconds the server returned.
class OtpCooldownStore {
  static String _key(String scope) => 'otp_cooldown_${scope.hashCode}';

  /// Record a cooldown of [seconds] for [scope] (e.g. `login:+965…`).
  static Future<void> record(String scope, int seconds) async {
    if (seconds <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final endMs = DateTime.now()
        .add(Duration(seconds: seconds))
        .millisecondsSinceEpoch;
    await prefs.setInt(_key(scope), endMs);
  }

  /// Seconds left on [scope]'s cooldown, or 0 if none/expired.
  static Future<int> remaining(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final endMs = prefs.getInt(_key(scope)) ?? 0;
    final leftMs = endMs - DateTime.now().millisecondsSinceEpoch;
    return leftMs > 0 ? (leftMs / 1000).ceil() : 0;
  }
}

/// Counts down the OTP "resend" cooldown as a pure-UI timer. Screens `start()`
/// it with the seconds the server returned and disable the resend button while
/// [value] > 0. Pair with [OtpCooldownStore] to persist across navigation.
class ResendCooldown extends ValueNotifier<int> {
  Timer? _timer;

  ResendCooldown() : super(0);

  bool get isActive => value > 0;

  void start(int seconds) {
    _timer?.cancel();
    if (seconds <= 0) {
      value = 0;
      return;
    }
    value = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (value <= 1) {
        value = 0;
        t.cancel();
      } else {
        value -= 1;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

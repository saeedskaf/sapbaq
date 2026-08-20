import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether a payment surface is currently on screen.
///
/// Every guard on the payment page defends against the customer *choosing* to
/// leave — a back gesture, the ✕, a swipe. None of them defends against the app
/// navigating away by itself, and one thing does exactly that: a push
/// notification arriving mid-payment. Tapping it deep-links away from a page
/// the customer is halfway through paying on, with no confirmation and no way
/// back to the same gateway session.
///
/// So payment surfaces raise this flag, and `SapbaqApp` holds the pending
/// deep-link instead of following it. Nothing is dropped — the route stays
/// queued and fires the moment the flag falls, so the customer lands on the
/// notification's screen right after paying rather than instead of it.
///
/// The foreground *banner* is deliberately left alone: seeing it costs nothing,
/// and suppressing it would risk losing a notification outright. Only the
/// navigation is deferred.
class PaymentActivity {
  PaymentActivity._();

  /// True while a payment page or sheet is on screen.
  static final ValueNotifier<bool> inFlight = ValueNotifier(false);

  /// Nested payment surfaces are possible (a 3-D Secure page opened over a
  /// payment sheet), so this counts rather than flips — the flag falls only
  /// when the last one closes.
  static int _depth = 0;

  static void begin() {
    _depth++;
    if (_depth == 1) {
      inFlight.value = true;
      _setSecure(true);
    }
  }

  static void end() {
    if (_depth == 0) return;
    _depth--;
    if (_depth == 0) {
      inFlight.value = false;
      _setSecure(false);
    }
  }

  static const _secure = MethodChannel('sapbaq/secure_screen');

  /// Keeps payment screens out of screenshots, screen recordings and the task
  /// switcher's thumbnail, via `FLAG_SECURE` on Android (see `MainActivity.kt`).
  ///
  /// The card fields belong to the gateway, so this is not about our own
  /// leakage: it is about screen-recording malware and the over-the-shoulder
  /// task-switcher preview a card number would otherwise sit in.
  ///
  /// **iOS is deliberately not covered.** UIKit has no equivalent flag, and the
  /// approaches that approximate one are fragile enough that claiming the
  /// protection would be worse than not having it. Said plainly here so nobody
  /// reads this as cross-platform.
  ///
  /// Failure is swallowed on purpose: a device that refuses the flag must not
  /// stop someone paying.
  static void _setSecure(bool on) {
    if (!Platform.isAndroid) return;
    _secure.invokeMethod<void>('setSecure', {'enabled': on}).catchError((_) {});
  }
}

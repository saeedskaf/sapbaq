import 'dart:async';

import 'package:flutter/foundation.dart';

/// Counts down the OTP "resend" cooldown (Sapbaq_AUTH_Flow §8: resend disabled
/// for 60s after each send). A pure-UI timer, independent of the network cubit:
/// screens `start()` it when a code is sent and disable the resend button while
/// [value] > 0.
class ResendCooldown extends ValueNotifier<int> {
  Timer? _timer;

  ResendCooldown() : super(0);

  bool get isActive => value > 0;

  void start([int seconds = 60]) {
    _timer?.cancel();
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

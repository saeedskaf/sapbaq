import 'package:shared_preferences/shared_preferences.dart';

/// Remembers payment attempts that were started but whose outcome we never
/// learned.
///
/// Every guard on the payment page assumes the app is still running. None of
/// them survives the OS killing it — memory pressure while the customer is on
/// their bank's 3-D Secure page, or simply a cold restart. When that happens
/// the route stack goes with it, `POST /payments/confirm/` is never called, and
/// the attempt sits `PENDING` on the server while the customer may well have
/// paid. Nothing in the app would ever mention it again.
///
/// So each id is written down before the payment page opens and read back on
/// the next launch, where `PaymentRecovery` confirms it. The stored values are
/// payment ids and timestamps — nothing secret, hence plain preferences rather
/// than the secure store.
///
/// **A set, not a single id.** It held one, and «ادفع الكل» can leave more than
/// one behind: a cart whose `confirm` came back still-undecided stays on the
/// list by design, and the next cart in the run then overwrote it. The first
/// payment was never asked about again — the one case this whole file exists
/// for, lost to the feature most likely to produce it.
class PendingPaymentStore {
  PendingPaymentStore._();

  static const _key = 'pending_payments';

  /// Past this, the server's own webhook and periodic reconciliation have long
  /// since settled the attempt, and asking again would only risk confusing the
  /// customer with a "payment confirmed" for something they've forgotten.
  static const Duration _maxAge = Duration(hours: 24);

  /// A cap, because this list is only ever trimmed by asking the server about
  /// each entry. A device that fails to reach us for a day should not build a
  /// queue that then costs a dozen calls on the next launch.
  static const int _maxEntries = 10;

  /// `<id>:<millisecondsSinceEpoch>`. Two numbers and a colon: a format worth
  /// keeping dull, because it is read on the launch path and a parse failure
  /// there would cost a real payment.
  static String _encode(int id, int at) => '$id:$at';

  static MapEntry<int, int>? _decode(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final id = int.tryParse(parts[0]);
    final at = int.tryParse(parts[1]);
    if (id == null || at == null) return null;
    return MapEntry(id, at);
  }

  static Future<void> record(int paymentId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final kept = <String>[
      for (final raw in prefs.getStringList(_key) ?? const <String>[])
        if (_decode(raw) case final entry?)
          // The same payment recorded twice is one attempt, not two — the
          // embedded route records again on every round of a retry.
          if (entry.key != paymentId && !_isStale(entry.value, now)) raw,
    ];
    kept.add(_encode(paymentId, now));
    await prefs.setStringList(
      _key,
      kept.length <= _maxEntries
          ? kept
          : kept.sublist(kept.length - _maxEntries),
    );
  }

  /// Unsettled attempts, oldest first, with anything aged out already dropped.
  static Future<List<int>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    final live = <String>[];
    final ids = <int>[];
    for (final line in raw) {
      final entry = _decode(line);
      if (entry == null || _isStale(entry.value, now)) continue;
      live.add(line);
      ids.add(entry.key);
    }
    // Written back so an aged-out entry is dropped even if nothing settles it.
    if (live.length != raw.length) await prefs.setStringList(_key, live);
    return ids;
  }

  /// Forget one settled attempt, leaving any others alone.
  static Future<void> clear(int paymentId) async {
    final prefs = await SharedPreferences.getInstance();
    final kept = [
      for (final raw in prefs.getStringList(_key) ?? const <String>[])
        if (_decode(raw)?.key != paymentId) raw,
    ];
    if (kept.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setStringList(_key, kept);
    }
  }

  static bool _isStale(int at, int now) => now - at > _maxAge.inMilliseconds;
}

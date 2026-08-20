import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/payments/pending_payment_store.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';

/// Settles a payment the app never got to confirm — see [PendingPaymentStore]
/// for how one comes to exist.
///
/// Run once per launch from the authenticated shell. `confirm` is idempotent
/// and re-queries the gateway server-side, so this is safe to call on an
/// attempt that already settled, and it is the same call the normal flow makes
/// — recovery is not a second source of truth, just a second chance to ask.
class PaymentRecovery {
  PaymentRecovery._();

  /// Returns true when **any** recovered attempt turns out to be paid — the one
  /// case worth telling the customer about. Anything else resolves quietly: an
  /// unpaid order is still sitting in «طلباتي» with its pay button, and
  /// announcing "your payment failed" for an attempt they abandoned days ago
  /// would alarm without informing.
  ///
  /// Every stored attempt is asked about, not just the newest. They are
  /// independent payments for independent orders, and stopping at the first
  /// would leave the rest unsettled for as long as the app keeps launching.
  static Future<bool> settlePending(PaymentRepository payments) async {
    var anyPaid = false;
    for (final id in await PendingPaymentStore.read()) {
      if (await _settle(payments, id)) anyPaid = true;
    }
    return anyPaid;
  }

  static Future<bool> _settle(PaymentRepository payments, int id) async {
    try {
      final settled = await payments.confirm(id);
      // Still undecided at the gateway — keep it and ask again next launch.
      if (!settled.isPending) await PendingPaymentStore.clear(id);
      return settled.isPaid;
    } on ApiException catch (e) {
      // The single most likely outcome here, and it means the customer PAID.
      // Recovery runs on an attempt the app never finished, so the webhook has
      // almost always settled it first — and the server answers a confirm on a
      // settled payment with this code. Reading it as just another 4xx would
      // throw away the one case worth telling them about.
      if (e.code == 'order_already_paid') {
        await PendingPaymentStore.clear(id);
        return true;
      }
      // Any other 4xx means the attempt is dead, not that the call failed: a
      // stale id after the cart changed, or one the server already closed.
      // Dropping it stops us re-asking on every launch forever. A network or
      // 5xx failure says nothing, so that one is kept for the next try.
      if (e.statusCode >= 400 && e.statusCode < 500) {
        await PendingPaymentStore.clear(id);
      }
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:sapbaq/core/config/environment.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/payments/payment_activity.dart';
import 'package:sapbaq/core/payments/payment_sheet.dart';
import 'package:sapbaq/core/payments/pending_payment_store.dart';
import 'package:sapbaq/features/orders/data/models/payment.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/features/orders/presentation/screens/payment_webview_screen.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// What became of a payment attempt.
enum PaymentOutcome {
  paid,
  failed,

  /// The bank refused the card **and the invoice is still payable** — another
  /// card on the same payment will work.
  ///
  /// Deliberately not [failed]: nothing is over, so no surface may show a final
  /// error, cancel what is being paid for, or send the customer away. And
  /// deliberately not [pending]: we know exactly what happened, and telling
  /// someone whose card was just declined to "check back later" is the report
  /// that started this.
  declined,

  /// Started but not settled — typically the customer closed the payment page
  /// mid-flow. The attempt may still complete; retrying is safe.
  pending,

  /// Couldn't even start (network, an expired hold, a closed payment window).
  /// [PaymentResult.message] carries the server's Arabic reason.
  notStarted,

  /// The customer closed the payment sheet without paying. Nothing was
  /// attempted and nothing was charged.
  ///
  /// Separate from [notStarted] because it is not a problem: a deliberate
  /// "not now" must not produce an error message. Callers should return
  /// silently and leave whatever is being paid for exactly as it was.
  dismissed,
}

class PaymentResult {
  final PaymentOutcome outcome;
  final Payment? payment;
  final String? message;

  /// The server's error code when the attempt never started — e.g.
  /// `hold_expired` for a lapsed marketplace claim.
  final String? code;

  /// The gateway sent the customer back through its *error* return, i.e. it
  /// declined the card rather than us failing to settle. Wording only — the
  /// verdict still comes from `confirm` — but it's the difference between
  /// "check your card" and "we couldn't confirm it".
  final bool declinedByGateway;

  const PaymentResult(
    this.outcome, {
    this.payment,
    this.message,
    this.code,
    this.declinedByGateway = false,
  });

  bool get isPaid => outcome == PaymentOutcome.paid;

  /// Started but unsettled — worth retrying, and worth *not* telling the
  /// customer their money is safe or gone until we know.
  bool get isPending => outcome == PaymentOutcome.pending;

  /// The customer backed out. Say nothing — they know what they did.
  bool get isDismissed => outcome == PaymentOutcome.dismissed;

  /// True when the gateway itself refused the card — the one failure the
  /// customer can actually act on.
  bool get isDeclined =>
      outcome == PaymentOutcome.declined ||
      (outcome == PaymentOutcome.failed && declinedByGateway);

  /// The refusal that isn't the end: the payment is still open at the gateway,
  /// so another card settles it.
  ///
  /// Callers must leave whatever is being paid for exactly as it is — claim
  /// still held, order still PENDING — and put a retry within reach instead of
  /// closing over it.
  bool get isRetryable => outcome == PaymentOutcome.declined;
}

/// Runs the whole payment: **initiate → (hosted page) → confirm**
/// (FLUTTER_PAYMENTS_MYFATOORAH §3).
///
/// Two rules hold this design together:
///
/// 1. **`confirm` is the only source of truth.** The gateway's return URL just
///    tells us when to close the browser. The server re-queries MyFatoorah
///    before settling, so a customer can't produce a "paid" state by
///    navigating, and an unrecognised return URL costs a tap, not a payment.
/// 2. **Always confirm, even after an abandoned page.** `confirm` is
///    idempotent, and the customer may well have paid before closing it.
///
/// In mock mode `initiate` returns no `redirect_url`; the browser step is then
/// skipped entirely and the same `confirm` settles it (§ mock note).
class PaymentGateway {
  final PaymentRepository _payments;
  const PaymentGateway(this._payments);

  /// [verifyPaid] re-reads the truth from the server when `confirm` itself
  /// fails — "did this actually go through?". The server settles payments on
  /// its own (a signed webhook within seconds, reconciliation within minutes),
  /// so a failed `confirm` says nothing about the money: only the order, the
  /// request or the contribution does. Callers that can answer that question
  /// should; without it an unsettled attempt stays [PaymentOutcome.pending].
  ///
  /// [destinationCount] is how many mosques this one payment settles. It used
  /// to be a "payment 1 of 3" counter, because «ادفع الكل» checked out a cart
  /// at a time and marched the customer through a page per mosque; the server
  /// now combines them, so the same slot answers the question that replaced it
  /// — "is this everything?" Leave it at 0 or 1 and nothing is shown.
  ///
  /// [target] opts this payment into the in-app sheet when embedded checkout is
  /// switched on. Everything about the fallback is deliberate: without a target,
  /// with the embed page unset, with cards off on the merchant account, or when
  /// the customer picks KNET — the hosted page runs exactly as it always has.
  /// There is one payment flow with a shortcut, not two flows.
  Future<PaymentResult> run(
    BuildContext context, {
    required Future<Payment> Function() initiate,
    Future<bool> Function()? verifyPaid,
    PaymentTarget? target,
    int destinationCount = 0,
  }) async {
    // The "payment in progress" flag is held here, across the WHOLE payment,
    // rather than by each surface for its own lifetime.
    //
    // The sheet and the 3-D Secure page each used to raise it themselves, which
    // left the flag briefly false in the handover between them — the sheet
    // disposes before the webview is pushed. A notification queued at that
    // instant would have been released into the gap, navigating away from a
    // payment mid-charge. `PaymentActivity` counts rather than flips, so the
    // surfaces can keep raising it too; the depth simply never reaches zero
    // until this returns.
    PaymentActivity.begin();
    try {
      return await _run(
        context,
        initiate: initiate,
        verifyPaid: verifyPaid,
        target: target,
        destinationCount: destinationCount,
      );
    } finally {
      PaymentActivity.end();
    }
  }

  /// How many times a refused card may be answered by reopening the sheet.
  ///
  /// Every round already needs a deliberate tap on «ادفع», so this cannot spin
  /// on its own — it is a guard against a gateway that decides to refuse
  /// everything, not against the customer. Three cards is more than anyone
  /// tries before reaching for another method.
  static const int _maxDeclineRounds = 2;

  /// A refused card does not close the invoice: the same payment stays payable
  /// so another card can settle it. So a decline reopens the payment sheet with
  /// the bank's own sentence at the top, rather than ending the run and leaving
  /// the customer to find their way back to a pay button.
  ///
  /// Only when the sheet is what they were on. After a hosted page there is
  /// nothing of ours to return them to, and the surfaces that started the
  /// payment already keep their «ادفع الآن» in place for exactly this.
  Future<PaymentResult> _run(
    BuildContext context, {
    required Future<Payment> Function() initiate,
    Future<bool> Function()? verifyPaid,
    PaymentTarget? target,
    int destinationCount = 0,
  }) async {
    PaymentResult? declined;
    String? notice;
    for (var round = 0; ; round++) {
      final result = await _attempt(
        context,
        initiate: initiate,
        verifyPaid: verifyPaid,
        target: target,
        destinationCount: destinationCount,
        notice: notice,
      );
      // Closing the reopened sheet is not "nothing happened". A card was
      // refused this run, and that — not silence — is what the customer needs
      // to be told.
      if (result.isDismissed && declined != null) return declined;
      if (!result.isRetryable) return result;
      declined = result;
      if (round >= _maxDeclineRounds ||
          !_sheetApplies(target) ||
          !context.mounted) {
        return result;
      }
      // The server promises a displayable sentence with every refusal; ours
      // only stands in if one ever fails to arrive, because a sheet that
      // reopens explaining nothing reads as the app having lost the payment.
      notice = result.message ?? AppLocalizations.of(context)!.payDeclinedBody;
    }
  }

  Future<PaymentResult> _attempt(
    BuildContext context, {
    required Future<Payment> Function() initiate,
    Future<bool> Function()? verifyPaid,
    PaymentTarget? target,
    int destinationCount = 0,
    String? notice,
  }) async {
    Payment? payment;
    if (_sheetApplies(target)) {
      final sheet = await _showSheet(context, target!, notice: notice);
      // Cancelled outright. Nothing was charged and nothing was even started,
      // so dropping the customer into the hosted page they just declined — as
      // a plain null once did — is the last thing to do.
      if (sheet == null) return const PaymentResult(PaymentOutcome.dismissed);
      // An attempt on the sheet's own session, whether it was charged there or
      // is being sent on to a hosted method the sheet can't run. Null only when
      // the sheet produced nothing at all and a fresh invoice is needed.
      payment = sheet.payment;
    }

    if (payment == null) {
      try {
        payment = await initiate();
      } on ApiException catch (e) {
        // The server settled it behind our back — a webhook, or the periodic
        // reconciliation, or simply a second tap. That is a success, not an
        // error, and the customer must not be shown a failure for money they
        // already paid (backend answers 2026-08-04).
        if (e.code == 'order_already_paid') {
          return const PaymentResult(PaymentOutcome.paid);
        }
        // `order_not_payable` (confirmed or cancelled meanwhile) travels as a
        // code too; the caller refreshes from the order rather than guessing.
        return PaymentResult(
          PaymentOutcome.notStarted,
          message: e.message,
          code: e.code,
        );
      }

      // Already settled server-side (e.g. re-initiating an attempt that went
      // through) — nothing left to do.
      //
      // Only reachable from `initiate`, and that is the point: its PAID comes
      // from the server's own record, whereas the sheet's status is a hint the
      // backend explicitly says not to trust. Letting a hint land here would
      // skip `confirm` and report a payment nobody verified.
      if (payment.isPaid) {
        return PaymentResult(PaymentOutcome.paid, payment: payment);
      }
    }

    // From here a charge may exist, whichever route produced it. Recording the
    // id now means an app killed before `confirm` is recoverable on next launch
    // — the embedded route has the same exposure as the hosted one, just a
    // shorter window.
    await PendingPaymentStore.record(payment.id);

    // Settled into a non-nullable local: the route builder below is a closure,
    // and a closure can't see the promotion that the null check above earned.
    final attempt = payment;

    PaymentReturn? returned;
    if (attempt.needsHostedPage) {
      if (!context.mounted) {
        return PaymentResult(PaymentOutcome.pending, payment: attempt);
      }
      returned = await Navigator.of(context, rootNavigator: true)
          .push<PaymentReturn>(
            MaterialPageRoute(
              // The whole attempt travels, not just the URL: the screen frames
              // the gateway's page with the amount and what it buys.
              builder: (_) => PaymentWebViewScreen(
                payment: attempt,
                destinationCount: destinationCount,
              ),
              // Also the first of the two guards that disable the iOS
              // back-swipe on this route (the other is its `PopScope`).
              fullscreenDialog: true,
            ),
          );
      // How they came back never decides the outcome — `confirm` does. It only
      // tells us how to word a failure.
    }

    try {
      final settled = await _payments.confirm(payment.id);
      // Three outcomes, not two: the gateway may still be deciding, and the
      // server deliberately leaves those PENDING rather than calling them
      // failed (backend answers §3). Reporting that as a failure would tell a
      // customer who did pay that they hadn't.
      //
      // Only a decided attempt is struck off the recovery list. A PENDING one
      // stays, so the next launch asks again and can still resolve it to PAID.
      if (!settled.isPending) await PendingPaymentStore.clear(attempt.id);
      // A refused card also comes back PENDING — the gateway keeps the invoice
      // open so another can be tried — so the refusal has to be read before the
      // status, not after it. Reading the status first is what produced "we
      // can't confirm it yet" for a customer whose card had just bounced.
      //
      // It stays on the recovery list either way, and that is right: it is
      // genuinely unsettled, and the next launch may well find it paid.
      final declined = settled.isDeclinedRetryable;
      return PaymentResult(
        settled.isPaid
            ? PaymentOutcome.paid
            : declined
            ? PaymentOutcome.declined
            : settled.isPending
            ? PaymentOutcome.pending
            : PaymentOutcome.failed,
        payment: settled,
        // The server's own Arabic sentence, written for this screen — never
        // `failureReason` or `lastAttemptError`, which read like
        // `InvoiceStatus=Failed` and belong in a support ticket. Null here
        // simply leaves our generic wording in place, which every caller
        // already falls back to.
        message: declined
            ? settled.lastAttemptMessageAr
            : settled.failureMessageAr,
        // A refund is not a refusal. It arrives through the same door as one —
        // not paid, and the customer came back through the gateway's error
        // return at some point — but "check your card and try another" is
        // wrong advice for money that was taken and given back.
        declinedByGateway:
            returned == PaymentReturn.error && !settled.isRefunded,
      );
    } on ApiException catch (e) {
      // Settled before we asked — the webhook usually beats us to it, and on a
      // recovered attempt it always does. The server now says so with a code
      // instead of a generic 400, so the customer's own successful payment
      // stops being reported to them as a failure.
      if (e.code == 'order_already_paid') {
        await PendingPaymentStore.clear(attempt.id);
        return PaymentResult(PaymentOutcome.paid, payment: payment);
      }
      // Otherwise, confirming failed — which tells us nothing on its own. It
      // happens both when the server already settled the payment and when the
      // attempt is dead (a stale id after the cart changed). Ask the thing being
      // paid for instead of reading the error.
      if (verifyPaid != null) {
        try {
          if (await verifyPaid()) {
            await PendingPaymentStore.clear(attempt.id);
            return PaymentResult(PaymentOutcome.paid, payment: payment);
          }
          // Verified unpaid: a definite failure the customer can act on, not an
          // open-ended "processing" they'd sit and wait through.
          await PendingPaymentStore.clear(attempt.id);
          return PaymentResult(
            PaymentOutcome.failed,
            payment: payment,
            message: e.message,
            code: e.code,
          );
        } on ApiException {
          // Couldn't check either — fall through to unsettled.
        }
      }
      // The charge may have landed even though confirming didn't — report it as
      // unsettled rather than failed, so the customer is offered a retry that
      // can still resolve to PAID.
      return PaymentResult(
        PaymentOutcome.pending,
        payment: payment,
        message: e.message,
        code: e.code,
      );
    }
  }

  /// Whether this payment is even a candidate for the in-app sheet. Kept
  /// separate from showing it so "the sheet never opened" and "the customer
  /// closed the sheet" stay distinguishable — they call for opposite responses.
  bool _sheetApplies(PaymentTarget? target) =>
      target != null && Environment.embeddedCheckoutEnabled;

  /// Null means the customer closed the sheet, or it couldn't be offered.
  ///
  /// [notice] is the bank's refusal from the round before, so a reopened sheet
  /// explains itself instead of coming back blank as though nothing happened.
  Future<PaymentSheetResult?> _showSheet(
    BuildContext context,
    PaymentTarget target, {
    String? notice,
  }) async {
    // Asked rather than assumed: a card or wallet that isn't live on the
    // merchant account would only fail after the customer had typed everything.
    final methods = await _payments.methods();
    if (!methods.card || !context.mounted) {
      // Not offered at all, which is not a cancellation — carry on to the
      // hosted page as though embedded checkout were switched off.
      return const PaymentSheetResult.hosted();
    }
    return PaymentSheet.show(
      context,
      payments: _payments,
      target: target,
      methods: methods,
      notice: notice,
    );
  }
}

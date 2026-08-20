import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sapbaq/core/auth/biometric_service.dart';
import 'package:sapbaq/core/config/environment.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/payments/payment_activity.dart';
import 'package:sapbaq/core/payments/payment_card_surface.dart';
import 'package:sapbaq/core/payments/payment_session.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/confirm_sheet.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/sheet_header.dart';
import 'package:sapbaq/features/orders/data/models/payment.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Which target a sheet is paying for. Exactly one id travels.
///
/// No caller supplies display text: the line under the amount is derived from
/// whichever id is set, by the same rule the hosted page's header uses, so the
/// two surfaces cannot drift into describing the same payment differently.
class PaymentTarget {
  final int? orderId;
  final int? contributionId;
  final int? equipmentRequestId;

  /// Mosques covered by this one payment. Only an order spans more than one:
  /// carts for several destinations now check out together, so the amount on
  /// the sheet may be settling three mosques at once and should say so.
  final int destinations;

  const PaymentTarget.order(int id, {this.destinations = 0})
    : orderId = id,
      contributionId = null,
      equipmentRequestId = null;

  const PaymentTarget.contribution(int id)
    : orderId = null,
      contributionId = id,
      equipmentRequestId = null,
      destinations = 0;

  const PaymentTarget.equipmentRequest(int id)
    : orderId = null,
      contributionId = null,
      equipmentRequestId = id,
      destinations = 0;

  String label(AppLocalizations l10n) {
    if (orderId != null) {
      final order = l10n.payForOrder(orderId!);
      // Which order it is and how much of their giving it settles are two
      // different questions, and a combined payment raises the second one.
      return destinations > 1
          ? '$order · ${l10n.mosquesCount(destinations)}'
          : order;
    }
    if (contributionId != null) return l10n.payForContribution;
    if (equipmentRequestId != null) return l10n.payForEquipment;
    return '';
  }
}

/// How a customer chose to pay.
enum _Method { savedCard, newCard }

/// How the sheet ended.
///
/// The distinction that matters is between *cancelled* and *pay another way*.
/// Both used to come back as null, so closing the sheet dropped the customer
/// straight into the hosted payment page they had just declined to use.
class PaymentSheetResult {
  /// The attempt this sheet produced — never a verdict, always something for
  /// `confirm` to settle. Null when the sheet couldn't produce one and the
  /// caller must start a hosted payment from scratch.
  ///
  /// It carries a `redirect_url` when the gateway wants the customer somewhere
  /// else first: a 3-D Secure challenge after a charge, or the hosted page for
  /// a method picked inside the embedded component. Both are the same shape and
  /// the same `payment_id`, which is why one field covers them.
  final Payment? payment;

  const PaymentSheetResult.attempt(Payment this.payment);

  /// Nothing was attempted — the customer picked KNET from the method list, or
  /// asked for the hosted page after a failure. A fresh invoice is needed.
  const PaymentSheetResult.hosted() : payment = null;
}

/// The in-app payment sheet.
///
/// Rises over what is being bought rather than replacing it, so the customer
/// never loses sight of what they are paying for — and matches the sheet
/// vocabulary the rest of the app already speaks (`ConfirmSheet`, the product
/// and destination sheets). There is no `AlertDialog` anywhere in this app and
/// this does not introduce one.
///
/// It owns the first two thirds of a payment: open a session, collect a card,
/// ask the server to charge it. It deliberately owns neither of the last two
/// steps — a 3-D Secure page and `confirm` both belong to [PaymentGateway], so
/// that "confirm is the only truth" stays true in exactly one file.
///
/// Returns a [Payment] describing the charged attempt, or null when the
/// customer backed out or chose a method that has to be paid on the hosted page.
/// Returning the same shape `initiate` does is what lets the gateway carry on
/// afterwards without knowing which route got here.
class PaymentSheet extends StatefulWidget {
  final PaymentRepository payments;
  final PaymentTarget target;
  final PaymentMethods methods;

  /// Why the sheet is open again: the bank's own sentence about the card it
  /// just refused. A refusal leaves the payment open, so the customer is
  /// brought back here to try another card — and a sheet that reopens without
  /// saying why reads as the app losing their payment.
  final String? notice;

  const PaymentSheet({
    super.key,
    required this.payments,
    required this.target,
    required this.methods,
    this.notice,
  });

  /// Shows the sheet. Null means "not paid here" — the caller falls back to the
  /// hosted page, which is always available.
  static Future<PaymentSheetResult?> show(
    BuildContext context, {
    required PaymentRepository payments,
    required PaymentTarget target,
    required PaymentMethods methods,
    String? notice,
  }) {
    return showModalBottomSheet<PaymentSheetResult>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Money must not leave by an accidental swipe; the ✕ asks first.
      isDismissible: false,
      enableDrag: false,
      builder: (_) => PaymentSheet(
        payments: payments,
        target: target,
        methods: methods,
        notice: notice,
      ),
    );
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  final _cardController = PaymentCardController();
  final _biometrics = BiometricService();

  PaymentSession? _session;
  _Method? _method;
  SavedCard? _chosenCard;
  bool _saveCard = false;

  /// Blocks every exit while the gateway is being talked to.
  bool _busy = false;

  /// The server's machine-readable code for whatever just failed, shown only in
  /// dev builds.
  ///
  /// Every payment failure otherwise looks the same on screen — one Arabic
  /// sentence — and telling `gateway_unavailable` from `order_not_payable` from
  /// `session_mismatch` meant asking the backend to read their logs. During a
  /// test round that is a whole round trip per failure. Customers never see it.
  String? _errorCode;

  /// The gateway refused our *setup*, not the customer's card — a bad key, a
  /// wrong endpoint. Retrying cannot help, so the sheet stops offering it.
  bool _misconfigured = false;

  /// A charge has been sent and not yet answered. Latches for the life of the
  /// sheet: once money is in flight there is no second attempt from here.
  bool _charging = false;

  /// Whether [PaymentSheet.notice] has been overtaken by this visit.
  ///
  /// It explains the *previous* card, so it belongs on screen only until the
  /// customer tries again — after that it is history sitting above a live
  /// attempt, and two refusals on screen at once say nothing clearly. Kept
  /// apart from [_error] so this visit's own failures land in one place with
  /// their own wording and their own retry.
  bool _noticeSpent = false;

  /// Nothing exits the sheet while [_busy], which is right — a half-sent card
  /// must not be abandoned mid-flight. It is also a trap if the embedded page
  /// never answers: a broken script, a dropped connection after load, a library
  /// that swallows its own error. Then the customer sits in a modal with no ✕,
  /// no back gesture and no spinner that ever stops.
  ///
  /// So collection is given a deadline. Generous, because a real bank round
  /// trip can be slow and cutting a live one short is worse than waiting.
  Timer? _collectDeadline;
  static const _collectTimeout = Duration(seconds: 45);
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    PaymentActivity.begin();
    _openSession();
  }

  @override
  void dispose() {
    _collectDeadline?.cancel();
    PaymentActivity.end();
    super.dispose();
  }

  void _startCollecting() {
    setState(() {
      _busy = true;
      _error = null;
      _noticeSpent = true;
    });
    _collectDeadline?.cancel();
    _collectDeadline = Timer(_collectTimeout, () {
      if (!mounted || !_busy) return;
      setState(() {
        _busy = false;
        _error = AppLocalizations.of(context)!.payNoResponse;
      });
    });
  }

  /// [saveCard] has to be settled before the session exists — MyFatoorah ties
  /// tokenization to the session, not to the charge — so flipping the toggle
  /// reopens one. That costs nothing: a session creates no gateway invoice, and
  /// the server hands back the same `payment_id` each time. The toggle sits
  /// above the card fields precisely so this never happens after typing.
  /// [keepError] holds the message already on screen instead of clearing it.
  ///
  /// A refused charge reopens the session straight away so the customer can try
  /// again — but the reopen used to blank `_error` on its way in, wiping the
  /// explanation a few milliseconds after it appeared. The payment failed, the
  /// sheet said nothing, and the only honest report was "I don't know what
  /// happened". A silent recovery must stay silent about the recovery, not
  /// about the failure that caused it.
  Future<void> _openSession({
    bool saveCard = false,
    bool keepError = false,
  }) async {
    setState(() {
      _loading = true;
      if (!keepError) _error = null;
    });
    try {
      final session = await widget.payments.openSession(
        orderId: widget.target.orderId,
        contributionId: widget.target.contributionId,
        equipmentRequestId: widget.target.equipmentRequestId,
        saveCard: saveCard,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
        // Land on the choice the customer is most likely to want: a saved card
        // if they have one, otherwise straight into the card fields.
        _method ??= session.savedCards.isNotEmpty
            ? _Method.savedCard
            : _Method.newCard;
        _chosenCard ??= session.savedCards.isNotEmpty
            ? session.savedCards.first
            : null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _misconfigured = e.code == 'gateway_misconfigured';
        _error = _misconfigured
            ? AppLocalizations.of(context)!.payMisconfigured
            : e.message;
        // The gateway's own status rides along in dev builds: `401` says our
        // key, `404` says our URL, absent says it never answered at all.
        final gatewayStatus = e.details['gateway_status'];
        _errorCode = gatewayStatus == null
            ? e.code
            : '${e.code}/gw:$gatewayStatus';
      });
    }
  }

  Future<void> _onSaveCardChanged(bool value) async {
    setState(() => _saveCard = value);
    await _openSession(saveCard: value);
  }

  /// The pay button. Collection happens inside the surface; this only asks for
  /// it and waits for [_onCardEvent].
  Future<void> _pay() async {
    final session = _session;
    if (session == null || _busy) return;
    HapticFeedback.selectionClick();

    if (_method == _Method.savedCard) {
      final card = _chosenCard;
      if (card == null) return;
      // A saved card can be charged by whoever holds an unlocked phone, so make
      // the phone prove it is still its owner. Cheap here — the app already
      // carries this for the passcode lock — and it is the difference between
      // "found phone" and "found wallet".
      if (!await _confirmIdentity()) return;
      _startCollecting();
      await _cardController.submitSavedCard(card.token);
      return;
    }

    _startCollecting();
    await _cardController.submitNewCard();
  }

  Future<bool> _confirmIdentity() async {
    if (!await _biometrics.isAvailable()) return true;
    if (!mounted) return false;
    return _biometrics.authenticate(
      reason: AppLocalizations.of(context)!.payBiometricReason,
    );
  }

  /// The surface has finished with the card. Nothing has been charged yet.
  Future<void> _onCardEvent(CardSurfaceReport report) async {
    _collectDeadline?.cancel();
    if (!mounted) return;
    // The gateway's callback is not promised to fire once. A double tap on its
    // own button, or a retry inside the library, would otherwise put a second
    // charge on the wire. The server refuses duplicates, but leaning on that is
    // how double charges happen the day its idempotency rule shifts — so the
    // second one never leaves this device.
    if (_charging) return;
    // A new card is submitted by the gateway's own button inside the frame, so
    // `_startCollecting` never runs for it and this is the first moment we know
    // the customer has tried again. The previous card's refusal is history from
    // here on and must not sit above a live attempt.
    if (!_noticeSpent) setState(() => _noticeSpent = true);
    // Picked a hosted method from inside the embedded component. Nothing was
    // collected, so charging the session is exactly what must not happen — an
    // empty session is refused in a way that reads to the customer like their
    // card failed.
    //
    // The gateway hands us where to send them, on this same payment, so follow
    // it: asking for a fresh invoice instead would make them choose their
    // method a second time on a page they were already past.
    if (report.event == CardSurfaceEvent.redirect) {
      final session = _session;
      Navigator.of(context).pop(
        report.isFollowable && session != null
            ? PaymentSheetResult.attempt(_pendingAttempt(session, report.url))
            // Nothing usable to follow — fall back to a hosted payment from
            // scratch, which is slower but always works.
            : const PaymentSheetResult.hosted(),
      );
      return;
    }
    if (report.event == CardSurfaceEvent.failed) {
      setState(() {
        _busy = false;
        _error =
            report.message ?? AppLocalizations.of(context)!.payCardRejected;
      });
      return;
    }
    await _execute();
  }

  /// An attempt for [PaymentGateway] to carry on with: the session's own
  /// payment, never settled here.
  ///
  /// The status is hard-coded PENDING rather than read from anywhere. The
  /// backend is explicit that its own `status` is a hint, and a "PAID" landing
  /// here would let the gateway skip `confirm` — the one call allowed to decide
  /// anything.
  Payment _pendingAttempt(
    PaymentSession session,
    String redirectUrl, {
    int? invoiceId,
    String? failureReason,
    String? failureMessageAr,
  }) => Payment(
    id: session.paymentId,
    status: 'PENDING',
    amount: session.amount,
    redirectUrl: redirectUrl,
    orderId: widget.target.orderId,
    contributionId: widget.target.contributionId,
    equipmentOrderId: widget.target.equipmentRequestId,
    invoiceId: invoiceId,
    failureReason: failureReason,
    failureMessageAr: failureMessageAr,
  );

  /// Ask the server to charge the session. The amount is its own; nothing from
  /// this screen influences what is taken.
  Future<void> _execute() async {
    final session = _session;
    if (session == null || _charging) return;
    _charging = true;
    try {
      final execution = await widget.payments.execute(
        paymentId: session.paymentId,
        sessionId: session.sessionId,
      );
      if (!mounted) return;
      // Whatever comes next — a 3-D Secure page or straight to `confirm` — is
      // the gateway's job, not the sheet's. Handing back the same shape
      // `initiate` returns is what lets it carry on without a second code path:
      // the amount rides along so a 3-D Secure page can still show what is
      // being paid.
      Navigator.of(context).pop(
        PaymentSheetResult.attempt(
          _pendingAttempt(
            session,
            execution.redirectUrl,
            invoiceId: execution.invoiceId,
            failureReason: execution.failureReason,
            failureMessageAr: execution.failureMessageAr,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      // Already settled — the webhook beat us to it, or this is a second tap on
      // a charge that went through. That is a success, and showing the customer
      // a red refusal for money they have paid is the worst reading available.
      //
      // It leaves by the same door as a normal charge, with nothing left to do:
      // an empty `redirect_url` sends the gateway straight to `confirm`, which
      // reports the payment for what it is instead of taking the sheet's word
      // for it.
      if (e.code == 'order_already_paid') {
        Navigator.of(
          context,
        ).pop(PaymentSheetResult.attempt(_pendingAttempt(session, '')));
        return;
      }

      // `no_card` is the one refusal that must NOT reopen the session, and it
      // has no exceptions.
      //
      // It means the gateway never received a card — the customer has not
      // finished typing one. Their details are still sitting on screen, and a
      // new session tears down the page and takes them with it: punishing an
      // incomplete form by wiping it. Every other reason (expired, already
      // spent, unrecognised) really is a dead session, and there a fresh one
      // costs nothing.
      //
      // This used to reopen on a *second* `no_card` for the same session, added
      // when a field name in the gateway's refusal was matching the backend's
      // `no_card` keywords and a genuinely dead session could arrive mislabelled
      // — the customer would then have been trapped forever. They fixed the
      // labelling, and the rule was left doing harm instead: pressing pay twice
      // on a half-typed card is exactly how a real customer produces two
      // `no_card`s in a row, and the second one wiped what they had typed.
      // Guarding against their mislabel by doing the thing their own rule
      // exists to prevent was the wrong trade.
      final reason = (e.details['reason'] ?? '').toString();

      final deadSession =
          e.code == 'session_mismatch' ||
          (e.code == 'payment_rejected' && reason != 'no_card');

      setState(() {
        _busy = false;
        // The charge was refused, not lost — let them try again.
        _charging = false;
        _errorCode = reason.isEmpty ? e.code : '${e.code}/$reason';
        // The server now writes a sentence per reason, in Arabic, for this
        // screen. Ours is the fallback, not the default.
        _error = e.message.trim().isNotEmpty
            ? e.message
            : AppLocalizations.of(context)!.paySessionStale;
      });
      // Keep the refusal on screen: the fresh session is housekeeping, the
      // message is the only thing the customer can act on.
      if (deadSession) {
        await _openSession(saveCard: _saveCard, keepError: true);
      }
    }
  }

  Future<void> _close() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final leave = await ConfirmSheet.ask(
      context,
      title: l10n.payCancelTitle,
      body: l10n.payCancelBody,
      icon: Icons.exit_to_app_rounded,
      danger: false,
      confirmLabel: l10n.payLeave,
      cancelLabel: l10n.payKeepGoing,
      invertEmphasis: true,
    );
    if (leave && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final session = _session;

    return PopScope(
      // Nothing leaves this sheet by gesture, and nothing at all leaves while
      // the gateway is mid-conversation.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                // 44 at the top is not arbitrary: it is exactly the strip the
                // drag handle used to occupy, so pinning the ✕ over it costs the
                // sheet no height at all.
                padding: EdgeInsets.fromLTRB(
                  20,
                  44,
                  20,
                  20 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_loading && session == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (session == null) ...[
                      const SizedBox(height: 12),
                      TextCustom.body(
                        text: _error ?? l10n.payFailedBody,
                        textAlign: TextAlign.center,
                        color: colors.textSecondary,
                      ),
                      _debugCode(colors),
                      const SizedBox(height: 20),
                      // No retry button on a misconfiguration. Our key or our URL is
                      // wrong, and pressing again a hundred times cannot fix either
                      // — offering the button would just make the customer perform
                      // our outage for us. Only the transient failures get a retry.
                      if (!_misconfigured)
                        ButtonCustom.secondary(
                          text: l10n.payRetry,
                          onPressed: () => _openSession(saveCard: _saveCard),
                        ),
                      // The way out, and on this branch it is the *only* way out.
                      //
                      // A session that never opened leaves nothing on screen to try
                      // again with, and a misconfiguration deliberately withholds
                      // even the retry — so without this the sheet is a dead end
                      // with a ✕, and a customer who wants to pay us cannot. The
                      // hosted page does not depend on any of what just failed.
                      if (widget.methods.knet || widget.methods.card) ...[
                        if (!_misconfigured) const SizedBox(height: 10),
                        ButtonCustom.secondary(
                          text: l10n.payUseHostedPage,
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(const PaymentSheetResult.hosted()),
                        ),
                      ],
                    ] else ...[
                      // Above the amount, not below the card fields where this
                      // sheet's own errors go: this one is the reason the sheet is
                      // open at all, and the fields are tall enough to push
                      // anything under them off the first screenful.
                      if (widget.notice != null && !_noticeSpent) ...[
                        _noticeBlock(widget.notice!, colors),
                        const SizedBox(height: 14),
                      ],
                      _amountBlock(session, l10n, colors),
                      const SizedBox(height: 14),
                      // Spacing belongs to the list, not to the layout: with no
                      // saved cards there is no list, and a gap held open for
                      // something that isn't there reads as a failed render.
                      if (_methodChoices(session, l10n, colors) case final tiles
                          when tiles.isNotEmpty) ...[
                        ...tiles,
                        const SizedBox(height: 10),
                      ],
                      // Hidden when the account can't tokenize: the gateway would
                      // ignore the choice silently, and a switch that does nothing
                      // is worse than no switch.
                      if (_method == _Method.newCard &&
                          widget.methods.saveCards)
                        _saveCardToggle(l10n),
                      // Mounted for BOTH methods, never conditionally.
                      //
                      // A saved card is charged by handing its token and the CVV to
                      // the gateway's library, which only exists once this page has
                      // loaded. Mounting the surface only for new cards left the
                      // controller unattached, so "pay" with a saved card called
                      // into nothing: no request, no error, a spinner that never
                      // stopped. It is collapsed rather than removed for saved
                      // cards — a platform view that isn't in the tree can't run
                      // the library that does the work.
                      _cardSurface(session),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        TextCustom.body(
                          text: _error!,
                          fontSize: 13,
                          color: context.colors.danger,
                        ),
                        // The one number support needs, in release too.
                        //
                        // Every payment ticket starts by finding the attempt at the
                        // gateway, and without this the customer has nothing to
                        // quote — the error sentence is the same for everyone, and
                        // matching it to an invoice takes a database dig. Small and
                        // grey on purpose: it is a serial number, not advice.
                        const SizedBox(height: 6),
                        TextCustom(
                          text: l10n.payReference(session.paymentId),
                          fontSize: 11,
                          color: colors.textHint,
                        ),
                        _debugCode(colors),
                        // A way out that always works.
                        //
                        // The in-app sheet depends on a gateway path we do not
                        // control, and it is currently failing inside MyFatoorah's
                        // own servers for reasons nobody here can fix. Without this,
                        // a donor who hits that has no way to pay at all — the sheet
                        // just keeps refusing. The hosted page has never stopped
                        // working, so offer it rather than strand them.
                        //
                        // Offered, not automatic: silently diverting to a web page
                        // would hide the fault from us and surprise the customer.
                        if (widget.methods.knet || widget.methods.card) ...[
                          const SizedBox(height: 12),
                          ButtonCustom.secondary(
                            text: l10n.payUseHostedPage,
                            onPressed: _busy
                                ? null
                                : () => Navigator.of(
                                    context,
                                  ).pop(const PaymentSheetResult.hosted()),
                          ),
                        ],
                      ],
                      // NO pay button of ours for a new card.
                      //
                      // MyFatoorah's card form renders its own submit button inside
                      // its iframe, and there is no way to suppress it:
                      // `useCustomButton` looks like the switch for it but belongs
                      // to Apple Pay — verified against the live library, and
                      // confirmed on device where both buttons showed up stacked.
                      //
                      // Two pay buttons on a payment screen is worse than a button
                      // in the wrong colour: the customer has to guess which one
                      // charges them. So theirs drives the card path, and the amount
                      // it omits is already the largest thing on the sheet.
                      //
                      // A saved card is different — nothing of theirs submits it, we
                      // call `submitCvv` ourselves — so that path keeps our button.
                      if (_method == _Method.savedCard) ...[
                        const SizedBox(height: 16),
                        ButtonCustom.primary(
                          text: l10n.payAmountAction(
                            l10n.priceKwd(session.amount),
                          ),
                          isLoading: _busy,
                          onPressed: _busy ? null : _pay,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _trustLine(l10n, colors),
                    ],
                  ],
                ),
              ),
              // Pinned to the corner, outside the scroll view.
              //
              // It used to ride inside the content, 20px of padding in from the
              // edge and free to scroll away — so on a phone where the card
              // fields push the sheet past a screenful, the only way out of a
              // payment scrolled off the top. A control that answers "how do I
              // get out of this?" has to be in the same place every second the
              // sheet is open.
              //
              // No drag handle beside it any more either. This sheet sets
              // `enableDrag: false` on purpose — money must not leave by an
              // accidental swipe — and a grabber advertising a gesture that is
              // deliberately dead is a small lie the ✕ then has to talk the
              // customer out of.
              //
              // Hidden while the gateway is mid-conversation, like the exit it
              // is: there is nothing to leave to while a card is in flight.
              if (!_busy)
                PositionedDirectional(
                  top: 12,
                  end: 12,
                  child: SheetCloseButton(size: 34, onTap: _close),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The bank's refusal of the previous card, in the server's own Arabic.
  ///
  /// Tinted rather than shouted: the payment is still open and another card
  /// settles it, so this is an instruction — «جرّب بطاقة أخرى» — not a verdict.
  Widget _noticeBlock(String message, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.credit_card_off_rounded,
            size: 18,
            color: colors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextCustom(
              text: message,
              fontSize: 13,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountBlock(
    PaymentSession session,
    AppLocalizations l10n,
    ThemeColors colors,
  ) {
    // Baseline-aligned on one line rather than stacked. The sheet is tall — a
    // card form, a method list and a toggle all have to fit above the fold —
    // and the purpose line does not need its own row to be read.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        TextCustom(
          text: l10n.priceKwd(session.amount),
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextCustom(
            text: widget.target.label(l10n),
            fontSize: 13,
            color: colors.textSecondary,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Cards, and only cards.
  ///
  /// KNET and the wallets used to sit here as tiles that closed the sheet and
  /// asked for the hosted page. They are gone because the gateway's own
  /// component already lists them inside the card frame: picking one there
  /// sends `redirect` over the bridge with the address to continue at, which is
  /// a shorter route to the same place than tearing our sheet down and asking
  /// the server for a fresh invoice. Two lists of payment methods a centimetre
  /// apart, one ours and one theirs, is a choice the customer should never have
  /// been asked to make.
  ///
  /// What this gives up, knowingly: §11 asks for the methods to be drawn from
  /// `/payments/methods/`, and Apple Pay is blocked inside the frame by §8-أ —
  /// so while embedded checkout is on, there is no route to the wallet at all.
  /// On the hosted page, which is where every payment goes while the embedded
  /// charge is broken at the gateway, it is offered natively and nothing is
  /// lost.
  ///
  /// Empty unless there is a genuine choice to make. With no saved cards the
  /// list is a single pre-selected row that cannot be operated — a control in
  /// the shape of a decision that has already been taken.
  List<Widget> _methodChoices(
    PaymentSession session,
    AppLocalizations l10n,
    ThemeColors colors,
  ) {
    if (session.savedCards.isEmpty) return const [];
    return [
      for (final card in session.savedCards)
        _MethodTile(
          selected: _method == _Method.savedCard && _chosenCard == card,
          title: card.masked,
          trailing: card.brand,
          icon: Icons.credit_card_rounded,
          onTap: _busy
              ? null
              : () => setState(() {
                  _method = _Method.savedCard;
                  _chosenCard = card;
                  _error = null;
                }),
        ),
      if (widget.methods.card)
        _MethodTile(
          selected: _method == _Method.newCard,
          title: l10n.payNewCard,
          icon: Icons.add_card_rounded,
          onTap: _busy
              ? null
              : () => setState(() {
                  _method = _Method.newCard;
                  _error = null;
                }),
        ),
    ];
  }

  /// Above the card fields on purpose: changing it reopens the session, and
  /// above means that can never discard something already typed.
  Widget _saveCardToggle(AppLocalizations l10n) {
    final colors = context.colors;
    // Tinted and boxed so it reads as part of the card block beneath it. Left
    // bare it floated between the method list and the fields, belonging to
    // neither — and a control whose subject is unclear gets ignored.
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
      child: SwitchListTile.adaptive(
        value: _saveCard,
        onChanged: _busy ? null : _onSaveCardChanged,
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: TextCustom(text: l10n.paySaveCard, fontSize: 13.5),
      ),
    );
  }

  Widget _cardSurface(PaymentSession session) {
    final showFields = _method == _Method.newCard;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          // Short for a saved card, but never hidden: that strip is the
          // gateway's own CVV input, and it is the only field the security code
          // can legitimately be typed into.
          //
          // Both numbers were measured against the live library rather than
          // guessed — its CVV iframe renders at 90px, so 72 clipped it.
          //
          // 320 for a new card, not 208: the page holds more than the three
          // rows — the gateway draws its own submit button under them. At 208
          // the fields were squeezed and that button pushed to the edge. Too
          // tall only costs whitespace; too short hides the control that takes
          // the payment.
          height: showFields ? 320 : 100,
          child: PaymentCardSurface(
            // A new session means a new page: the old one is bound to a session
            // that no longer accepts a card.
            key: ValueKey(session.sessionId),
            sessionId: session.sessionId,
            countryCode: session.countryCode,
            language: session.language,
            showFields: showFields,
            controller: _cardController,
            onEvent: _onCardEvent,
          ),
        ),
      ),
    );
  }

  /// The failing code, in staging builds only. Nothing in release: a customer
  /// has no use for `gateway_unavailable` and every reason not to be shown it.
  Widget _debugCode(ThemeColors colors) {
    if (!Environment.devMode || _errorCode == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextCustom(
        text: '⟨${_errorCode!}⟩',
        fontSize: 11,
        color: colors.textHint,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _trustLine(AppLocalizations l10n, ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, size: 13, color: colors.textHint),
        const SizedBox(width: 6),
        Flexible(
          child: TextCustom(
            text: l10n.paySecureNote,
            fontSize: 12,
            color: colors.textHint,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String? trailing;
  final IconData icon;
  final VoidCallback? onTap;

  const _MethodTile({
    required this.selected,
    required this.title,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: colors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: selected
              ? const BorderSide(color: ColorsCustom.brandMint, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            // Tighter than the app's usual list row: this sheet has to fit a
            // whole card form under these tiles without the pay control falling
            // below the fold.
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextCustom(
                    text: title,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (trailing != null)
                  TextCustom(
                    text: trailing!,
                    fontSize: 11,
                    color: colors.textHint,
                  ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

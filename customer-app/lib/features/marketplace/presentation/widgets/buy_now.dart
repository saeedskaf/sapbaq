import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/payments/payment_gateway.dart';
import 'package:sapbaq/core/payments/payment_sheet.dart';
import 'package:sapbaq/features/marketplace/data/marketplace_repository.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

enum BuyNowStatus { paid, expired, cancelled, failed, dismissed }

class BuyNowResult {
  final BuyNowStatus status;
  final String? message;
  final String? code;

  /// `error.details.remaining` verbatim — a package count for water, a money
  /// string at fils precision ("30.000") for an equipment campaign. Kept as
  /// text so neither shape is lossy; the caller parses what it expects.
  final String? remaining;

  const BuyNowResult(this.status, {this.message, this.code, this.remaining});
}

/// Claim (contribute) → pay step. Shows a blocking spinner during the claim,
/// then a bottom sheet with a live countdown and a pay button. On a 409 from
/// the claim, returns [BuyNowStatus.failed] with the server message/code so the
/// caller can recover (e.g. re-offer the remaining quantity). The caller should
/// always refresh the affected feed afterwards.
Future<BuyNowResult> runBuyNow(
  BuildContext context, {
  required MarketplaceRepository repo,
  required PaymentRepository payments,
  required String title,
  required Future<ContributionResult> Function() contribute,
}) async {
  ContributionResult result;
  try {
    result = await _blocking(context, contribute);
  } on ApiException catch (e) {
    return BuyNowResult(
      BuyNowStatus.failed,
      message: e.message,
      code: e.code,
      remaining: e.details['remaining']?.toString(),
    );
  }
  if (!context.mounted) return const BuyNowResult(BuyNowStatus.dismissed);
  return _showPaySheet(
    context,
    repo: repo,
    payments: payments,
    result: result,
    title: title,
  );
}

/// Reopen the pay step for an already-claimed, still-pending contribution
/// (e.g. from «مساهماتي» after backing out of the first attempt).
Future<BuyNowResult> resumePayment(
  BuildContext context, {
  required MarketplaceRepository repo,
  required PaymentRepository payments,
  required Contribution contribution,
  required String title,
}) {
  final result = ContributionResult(
    contributionId: contribution.id,
    amount: contribution.amount,
    expiresAt: contribution.expiresAt,
    holdSeconds: 0,
  );
  return _showPaySheet(
    context,
    repo: repo,
    payments: payments,
    result: result,
    title: title,
  );
}

/// Standard reaction to a buy-now outcome: a message where useful, then refresh
/// the feed (a claim always changes it, so [reload] runs for every outcome).
void handleBuyNowResult(
  BuildContext context,
  BuyNowResult res, {
  required VoidCallback reload,
}) {
  final l10n = AppLocalizations.of(context)!;
  switch (res.status) {
    case BuyNowStatus.paid:
      ShowMessage.success(context, l10n.paidThanks);
    case BuyNowStatus.expired:
      ShowMessage.info(context, l10n.backedToMarket);
    case BuyNowStatus.failed:
      ShowMessage.error(context, res.message ?? l10n.comingSoon);
    case BuyNowStatus.cancelled:
    case BuyNowStatus.dismissed:
      break;
  }
  reload();
}

Future<T> _blocking<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    // `canPop: false` matters as much as `barrierDismissible`: without it an
    // Android back gesture closes the spinner, and the pop below then takes
    // the screen underneath with it.
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  try {
    return await action();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

Future<BuyNowResult> _showPaySheet(
  BuildContext context, {
  required MarketplaceRepository repo,
  required PaymentRepository payments,
  required ContributionResult result,
  required String title,
}) async {
  final r = await showModalBottomSheet<BuyNowResult>(
    context: context,
    useRootNavigator: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _PayStepSheet(
      repo: repo,
      payments: payments,
      gateway: PaymentGateway(payments),
      result: result,
      title: title,
    ),
  );
  return r ?? const BuyNowResult(BuyNowStatus.dismissed);
}

class _PayStepSheet extends StatefulWidget {
  final MarketplaceRepository repo;
  final PaymentRepository payments;
  final PaymentGateway gateway;
  final ContributionResult result;
  final String title;
  const _PayStepSheet({
    required this.repo,
    required this.payments,
    required this.gateway,
    required this.result,
    required this.title,
  });

  @override
  State<_PayStepSheet> createState() => _PayStepSheetState();
}

class _PayStepSheetState extends State<_PayStepSheet> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _busy = false;
  bool _expired = false;

  /// The bank's refusal of the card just tried, kept on the sheet so trying
  /// another is one tap away and the reason is still readable while they do it.
  String? _error;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    if (_remaining <= Duration.zero) {
      _expired = true;
    } else {
      _startTimer();
    }
  }

  /// The countdown is frozen whenever the customer leaves for a payment surface
  /// and restarted when they come back without having paid, so it never runs
  /// down under a screen they cannot see.
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Duration _computeRemaining() {
    final exp = widget.result.expiresAt;
    if (exp == null) return const Duration(minutes: 5);
    return exp.difference(DateTime.now());
  }

  void _tick() {
    final r = _computeRemaining();
    if (r <= Duration.zero) {
      _timer?.cancel();
      if (mounted) setState(() => _expired = true);
    } else {
      if (mounted) setState(() => _remaining = r);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    // A live gateway opens its own page, which can outlast the claim's hold —
    // so freeze the countdown while the customer is away instead of letting it
    // run out under a screen they can't see.
    _timer?.cancel();

    final result = await widget.gateway.run(
      context,
      initiate: () => widget.payments.initiateContributionPayment(
        widget.result.contributionId,
      ),
      target: PaymentTarget.contribution(widget.result.contributionId),
      // A failed `confirm` proves nothing — the contribution does.
      verifyPaid: () async =>
          (await widget.repo.contribution(
            widget.result.contributionId,
          )).contribution.status !=
          ContributionStatus.pending,
    );
    if (!mounted) return;

    // Backed out of the payment sheet. Stay on the buy sheet with the claim
    // still held and the countdown running again, so they can simply try again.
    if (result.isDismissed) {
      setState(() => _busy = false);
      _startTimer();
      return;
    }
    // The bank refused the card, and that is not the end of anything: the claim
    // is still ours and the payment is still open at the gateway. So stay here
    // with the refusal in view and the countdown running, rather than closing
    // over a payment the customer can finish with another card.
    if (result.isRetryable) {
      setState(() {
        _busy = false;
        _error =
            result.message ?? AppLocalizations.of(context)!.payDeclinedBody;
      });
      _startTimer();
      return;
    }
    if (result.isPaid) {
      Navigator.pop(context, const BuyNowResult(BuyNowStatus.paid));
      return;
    }
    if (result.isPending) {
      // Unsettled, not refused — say so instead of "payment failed", and leave
      // the contribution claimed so it can be retried from «مساهماتي».
      Navigator.pop(
        context,
        BuyNowResult(
          BuyNowStatus.failed,
          message: AppLocalizations.of(context)!.payPendingBody,
        ),
      );
      return;
    }
    // The hold lapsing is its own outcome, not a payment failure: the item went
    // back to the market and the customer was not charged.
    if (result.code == 'hold_expired') {
      setState(() {
        _busy = false;
        _expired = true;
      });
      return;
    }
    Navigator.pop(
      context,
      BuyNowResult(
        BuyNowStatus.failed,
        message:
            result.message ??
            (result.isDeclined
                ? AppLocalizations.of(context)!.payDeclinedBody
                : AppLocalizations.of(context)!.payFailedBody),
        code: result.code,
      ),
    );
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    try {
      await widget.repo.cancelContribution(widget.result.contributionId);
    } catch (_) {
      // Best-effort — the hold expires on its own regardless.
    }
    if (mounted) {
      Navigator.pop(context, const BuyNowResult(BuyNowStatus.cancelled));
    }
  }

  String _fmt(Duration d) {
    final s = d.inSeconds.clamp(0, 5999);
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: _expired ? _expiredView(l10n) : _payView(l10n),
        ),
      ),
    );
  }

  Widget _expiredView(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Icon(Icons.timer_off_rounded, size: 48, color: context.colors.danger),
        const SizedBox(height: 14),
        TextCustom.subheading(
          text: l10n.holdExpiredTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TextCustom(
          text: l10n.holdExpiredBody,
          fontSize: 14,
          color: context.colors.textSecondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        ButtonCustom.primary(
          text: l10n.closeButton,
          onPressed: () =>
              Navigator.pop(context, const BuyNowResult(BuyNowStatus.expired)),
        ),
      ],
    );
  }

  Widget _payView(AppLocalizations l10n) {
    final low = _remaining.inSeconds <= 30;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextCustom.subheading(text: widget.title),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextCustom(
              text: l10n.amountLabel,
              fontSize: 14,
              color: context.colors.textSecondary,
            ),
            TextCustom(
              text: l10n.priceKwd(widget.result.amount),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.colors.primary,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: low
                ? context.colors.danger.withValues(alpha: 0.10)
                : context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 20,
                color: low ? context.colors.danger : context.colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextCustom(
                  text: l10n.timeLeftLabel,
                  fontSize: 13,
                  color: context.colors.textSecondary,
                ),
              ),
              TextCustom(
                text: _fmt(_remaining),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: low ? context.colors.danger : context.colors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextCustom(
          text: l10n.payWindowNote,
          fontSize: 12,
          color: context.colors.textHint,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.colors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.credit_card_off_rounded,
                  size: 18,
                  color: context.colors.danger,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextCustom(
                    text: _error!,
                    fontSize: 13,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ButtonCustom.primary(
          text: l10n.payNow,
          isLoading: _busy,
          onPressed: _busy ? null : _pay,
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _busy ? null : _cancel,
          child: TextCustom(
            text: l10n.cancelButton,
            fontSize: 14,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

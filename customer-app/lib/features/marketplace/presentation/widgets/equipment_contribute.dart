import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/auth/auth_guard.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/marketplace/data/marketplace_repository.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/buy_now.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/marketplace_card.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The full equipment-campaign contribution flow, reused by the equipment tab
/// and the model sheet: auth gate → amount sheet (clamped to what's left) →
/// buy-now (claim + pay). [reload] refreshes the feed afterwards.
///
/// Campaigns are funded by several donors at once, so another donor can take
/// the rest of the goal between opening the sheet and claiming. That comes back
/// as `amount_exceeds_remaining` with the true remainder — the sheet reopens on
/// the corrected ceiling instead of dead-ending on an error.
Future<void> startEquipmentContribution(
  BuildContext context,
  EquipmentListing listing, {
  required VoidCallback reload,
}) async {
  final funding = listing.funding;
  if (funding == null) return;

  // The feed can be a few seconds stale: the goal may have been met (or fully
  // claimed) while the card sat on screen. Say so and refresh instead of
  // opening an amount sheet with nothing left to give.
  if (funding.isClosed) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errListingClosed)),
      );
    reload();
    return;
  }
  if (!ensureAuthenticated(context)) return;

  var ceiling = funding.remaining;
  while (true) {
    final amount = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AmountSheet(
        listing: listing,
        // Everything but the ceiling stays as it was read: a mid-flight
        // correction only ever shrinks what's left to fund.
        funding: ceiling == funding.remaining
            ? funding
            : EquipmentFunding(
                targetAmount: funding.targetAmount,
                fundedAmount: funding.fundedAmount,
                reservedAmount: funding.reservedAmount,
                remaining: ceiling,
                progress: funding.progress,
              ),
      ),
    );
    if (amount == null || !context.mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<MarketplaceRepository>();
    final res = await runBuyNow(
      context,
      repo: repo,
      payments: context.read<PaymentRepository>(),
      title: listing.title,
      contribute: () => repo.contributeEquipment(
        equipmentRequestId: listing.requestId,
        amount: amount,
      ),
    );
    if (!context.mounted) return;

    final failed = res.status == BuyNowStatus.failed;
    final corrected = res.remaining;
    final left = double.tryParse(corrected ?? '') ?? 0;

    // Another donor claimed part of the goal first — retry on the real
    // remainder rather than making this one guess.
    if (failed && res.code == 'amount_exceeds_remaining' && left > 0) {
      ceiling = corrected!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.errAmountExceedsRemaining(corrected))),
        );
      reload();
      continue;
    }

    // Nothing left at all: the campaign closed under us. The app is bilingual
    // and the server's message is Arabic-only, so translate a code we know.
    if (failed &&
        (res.code == 'listing_closed' ||
            res.code == 'amount_exceeds_remaining')) {
      handleBuyNowResult(
        context,
        BuyNowResult(BuyNowStatus.failed, message: l10n.errListingClosed),
        reload: reload,
      );
      return;
    }

    handleBuyNowResult(context, res, reload: reload);
    return;
  }
}

/// Amount chooser for a campaign contribution: a free-typed decimal field
/// clamped to what's left, a "fund the rest" shortcut, and a live view of where
/// the campaign stands. Pops the amount as a money string.
class _AmountSheet extends StatefulWidget {
  final EquipmentListing listing;
  final EquipmentFunding funding;
  const _AmountSheet({required this.listing, required this.funding});

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _controller = TextEditingController();

  /// Fils precision (3 decimals), matching what the endpoint accepts.
  static final _decimal = RegExp(r'^\d{0,6}(\.\d{0,3})?$');

  double get _max => widget.funding.remainingValue;
  double get _value => double.tryParse(_controller.text.trim()) ?? 0;
  bool get _isValid => _value > 0 && _value <= _max;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Clamp to the remaining goal as the donor types — the server would refuse
  /// anything above it anyway, and a silent correction beats a rejected claim.
  void _onTyped(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed != null && parsed > _max) {
      _fill(_max);
      return;
    }
    setState(() {});
  }

  void _fill(double value) {
    final text = _trim(value);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  /// "40.00" → "40", "40.50" → "40.5" — a filled-in field should read like
  /// something a person would type.
  static String _trim(double value) {
    final text = value.toStringAsFixed(2);
    if (!text.contains('.')) return text;
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
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
          // Lift the sheet above the keyboard so the field stays visible.
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
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
                TextCustom.subheading(text: l10n.contributeAmountTitle),
                if (widget.listing.variant != null) ...[
                  const SizedBox(height: 4),
                  TextCustom(
                    text: widget.listing.title,
                    fontSize: 13,
                    color: context.colors.textSecondary,
                  ),
                ],
                const SizedBox(height: 16),
                FundingProgress(funding: widget.funding),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        autofocus: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          TextInputFormatter.withFunction(
                            (old, now) =>
                                _decimal.hasMatch(now.text) ? now : old,
                          ),
                        ],
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: context.colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: '0',
                          suffixText: l10n.currencyKwd,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: context.colors.border,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: context.colors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: _onTyped,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _max > 0 ? () => _fill(_max) : null,
                      child: TextCustom(
                        text: l10n.fundRemainder,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextCustom(
                  text: l10n.noRefundNote,
                  fontSize: 12,
                  color: context.colors.textHint,
                ),
                const SizedBox(height: 16),
                ButtonCustom.primary(
                  text: _isValid
                      ? '${l10n.contributeAction} • '
                            '${l10n.priceKwd(_trim(_value))}'
                      : l10n.contributeAction,
                  onPressed: _isValid
                      ? () => Navigator.pop(context, _value.toStringAsFixed(2))
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/auth/auth_guard.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/marketplace/data/marketplace_repository.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/buy_now.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The full water-contribution flow, reused by the water tab and the mosque
/// detail card: auth gate → package-quantity sheet (clamped to the remaining
/// cap) → buy-now (claim + pay). [reload] refreshes whatever surface launched
/// it after the attempt.
Future<void> startWaterPurchase(
  BuildContext context,
  WaterListing listing, {
  required VoidCallback reload,
}) async {
  if (!ensureAuthenticated(context)) return;
  final packages = await showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _WaterQtySheet(listing: listing),
  );
  if (packages == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final repo = context.read<MarketplaceRepository>();
  final res = await runBuyNow(
    context,
    repo: repo,
    payments: context.read<PaymentRepository>(),
    title: l10n.mosqueNeedsTitle,
    contribute: () => repo.contributeWater(
      restockFlagId: listing.restockFlagId,
      packages: packages,
    ),
  );
  if (context.mounted) handleBuyNowResult(context, res, reload: reload);
}

/// Quantity chooser for a water contribution — steppers plus a free-typed
/// number field, all clamped to the remaining cap, with a live amount. Pops the
/// chosen package count.
class _WaterQtySheet extends StatefulWidget {
  final WaterListing listing;
  const _WaterQtySheet({required this.listing});

  @override
  State<_WaterQtySheet> createState() => _WaterQtySheetState();
}

class _WaterQtySheetState extends State<_WaterQtySheet> {
  late final TextEditingController _controller;
  int _qty = 1;

  int get _max => widget.listing.cap.remaining;
  double get _unit => double.tryParse(widget.listing.package.price) ?? 0;
  // Two decimals — the server serializes money that way, and a locally
  // computed total sitting next to a server price must not read differently.
  String get _amount => (_unit * _qty).toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Clamp to [1, max], store, and sync the field. Used by the steppers and to
  /// finalize free-typed input.
  void _setQty(int value) {
    final ceiling = _max < 1 ? 1 : _max;
    final clamped = value.clamp(1, ceiling);
    setState(() => _qty = clamped);
    final text = '$clamped';
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  /// Live parse while typing: allow a transient empty value (qty 0 → donate
  /// disabled) so the field can be cleared and retyped, but keep the qty capped.
  void _onTyped(String raw) {
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      setState(() => _qty = 0);
      return;
    }
    if (parsed > _max) {
      _setQty(_max);
      return;
    }
    setState(() => _qty = parsed);
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
        child: SingleChildScrollView(
          // Lift the sheet above the keyboard so the number field stays visible.
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
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
              TextCustom.subheading(text: l10n.waterQtyTitle),
              const SizedBox(height: 6),
              TextCustom(
                text: l10n.remainingPackages(_max),
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepBtn(
                    icon: Icons.remove_rounded,
                    onTap: _qty > 1 ? () => _setQty(_qty - 1) : null,
                  ),
                  SizedBox(
                    width: 96,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: context.colors.border),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: context.colors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: _onTyped,
                      onEditingComplete: () => _setQty(_qty),
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                        _setQty(_qty);
                      },
                    ),
                  ),
                  _StepBtn(
                    icon: Icons.add_rounded,
                    onTap: _qty < _max ? () => _setQty(_qty + 1) : null,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ButtonCustom.primary(
                text: '${l10n.donate} • ${l10n.priceKwd(_amount)}',
                onPressed: _qty >= 1
                    ? () => Navigator.pop(context, _qty)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? ColorsCustom.brandMint : context.colors.surfaceVariant,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: enabled ? ColorsCustom.onMint : context.colors.textHint,
          ),
        ),
      ),
    );
  }
}

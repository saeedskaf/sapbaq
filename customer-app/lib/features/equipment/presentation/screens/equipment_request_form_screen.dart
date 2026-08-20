import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/image_carousel.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/most_needed_badge.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/equipment/data/equipment_repository.dart';
import 'package:sapbaq/features/mosques/presentation/screens/mosque_picker_screen.dart';
import 'package:sapbaq/features/products/data/models/product.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// What the storefront hands the request form: the approval product, the
/// combination the donor picked (null when the product has no variants), and
/// the destination already chosen in the destination bar.
class EquipmentRequestArgs {
  final Product product;
  final ProductVariant? variant;
  final DonationDestination? destination;

  const EquipmentRequestArgs({
    required this.product,
    this.variant,
    this.destination,
  });
}

/// Files an approval-path request: which product/variant, for which mosque,
/// with an optional engraving. Nothing is charged here — the request lands
/// `UNDER_REVIEW` and a manager decides (delivery §3).
class EquipmentRequestFormScreen extends StatefulWidget {
  final EquipmentRequestArgs args;
  const EquipmentRequestFormScreen({super.key, required this.args});

  @override
  State<EquipmentRequestFormScreen> createState() =>
      _EquipmentRequestFormScreenState();
}

class _EquipmentRequestFormScreenState
    extends State<EquipmentRequestFormScreen> {
  final _dedicationController = TextEditingController();

  late DonationDestination? _destination = widget.args.destination;

  /// Off by default in every product without exception — the engraving is an
  /// offer, not a step.
  bool _engrave = false;
  String _dedicationStatus = 'ALIVE';
  bool _busy = false;

  Product get _product => widget.args.product;
  ProductVariant? get _variant => widget.args.variant;

  @override
  void dispose() {
    _dedicationController.dispose();
    super.dispose();
  }

  /// Reuses the donation flow's mosque browser (governorate → area → mosque).
  Future<void> _pickMosque() async {
    final picked = await Navigator.of(context).push<DonationDestination>(
      MaterialPageRoute(builder: (_) => const MosquePickerScreen()),
    );
    if (picked == null || !mounted) return;
    setState(() => _destination = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final destination = _destination;
    if (destination == null) {
      ShowMessage.error(context, l10n.equipMosqueRequired);
      return;
    }
    final name = _dedicationController.text.trim();
    if (_engrave && name.isEmpty) {
      ShowMessage.error(context, l10n.dedicationNameRequired);
      return;
    }

    setState(() => _busy = true);
    try {
      await context.read<EquipmentRepository>().createRequest(
        mosqueId: destination.mosqueId,
        productId: _product.id,
        variantId: _variant?.id,
        viaMostNeeded: destination.viaMostNeeded,
        dedicationName: _engrave ? name : null,
        dedicationStatus: _engrave ? _dedicationStatus : null,
      );
      if (!mounted) return;
      ShowMessage.success(context, l10n.equipSubmitted);
      // Straight to «طلباتي», where the request now waits for review — and
      // where the pay button will appear once it's approved.
      context.pushReplacementNamed(AppRoutes.ordersName);
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destination = _destination;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: TextCustom.subheading(text: l10n.equipRequestTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(product: _product, variant: _variant),
          const SizedBox(height: 20),
          TextCustom(
            text: l10n.equipPickMosque,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _busy ? null : _pickMosque,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.mosque_outlined, color: context.colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextCustom(
                      text: destination?.label ?? l10n.equipMosqueRequired,
                      fontSize: 14,
                      fontWeight: destination == null
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: destination == null
                          ? context.colors.textHint
                          : context.colors.textPrimary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (destination?.isMostNeeded ?? false) ...[
                    const SizedBox(width: 8),
                    const MostNeededBadge(),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textHint,
                  ),
                ],
              ),
            ),
          ),
          // The engraving is offered only when the product supports it; when it
          // doesn't, the customer sees no trace of it at all.
          if (_product.supportsDedication) ...[
            const SizedBox(height: 22),
            TextCustom(
              text: l10n.equipDedicationTitle,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _engrave,
              onChanged: _busy ? null : (v) => setState(() => _engrave = v),
              title: TextCustom(
                text: l10n.dedicationEngraveToggle,
                fontSize: 13.5,
              ),
            ),
            if (_engrave) ...[
              // Status first, then the name — the order the donor thinks in.
              Row(
                children: [
                  for (final entry in [
                    ('ALIVE', l10n.dedicationAlive),
                    ('DECEASED', l10n.dedicationDeceased),
                  ]) ...[
                    ChoiceChip(
                      label: TextCustom(
                        text: entry.$2,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _dedicationStatus == entry.$1
                            ? Theme.of(context).colorScheme.onPrimary
                            : context.colors.textPrimary,
                      ),
                      selected: _dedicationStatus == entry.$1,
                      selectedColor: context.colors.primary,
                      onSelected: _busy
                          ? null
                          : (_) => setState(() => _dedicationStatus = entry.$1),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              FormFieldCustom(
                controller: _dedicationController,
                label: l10n.equipDedicationName,
                enabled: !_busy,
              ),
            ],
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextCustom(
                    // The window length is a dashboard setting, never a
                    // hard-coded 48 (delivery §1.3).
                    text: l10n.equipNoteUnderReview(
                      _product.approval?.payWindowHours ?? 48,
                    ),
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ButtonCustom.primary(
            text: l10n.equipSubmit,
            isLoading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Product product;
  final ProductVariant? variant;
  const _SummaryCard({required this.product, required this.variant});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final image = variant?.image ?? product.image ?? '';
    final price = variant?.effectivePrice ?? product.effectivePrice;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border, width: 0.6),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: ColoredBox(
                color: context.colors.surfaceVariant,
                child: ContainedImage(url: image, padding: 6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: product.name,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variant != null) ...[
                  const SizedBox(height: 3),
                  TextCustom(
                    // The composed label comes from the server — never built
                    // here, so it reads the same everywhere.
                    text: variant!.name,
                    fontSize: 12.5,
                    color: context.colors.textSecondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                TextCustom(
                  text: l10n.priceKwd(price),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

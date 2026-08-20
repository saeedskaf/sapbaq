import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/models/equipment_option.dart';
import 'package:sapbaq_admin/features/shared/presentation/model_thumb.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Picks the product **and** the exact combination an equipment request will be
/// fulfilled with. Approving is no longer a yes/no: the pick fixes the campaign
/// goal (a snapshot of the variant's price), so it happens before publishing
/// (delivery §6.3).
///
/// Same axes and chips the donor sees in the store — one serializer, one
/// mental model. Resolves to the pick, or null when dismissed.
Future<EquipmentPick?> showEquipmentPickSheet(
  BuildContext context, {
  required Future<List<EquipmentOption>> Function() load,
  String? title,
}) {
  return showModalBottomSheet<EquipmentPick>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EquipmentPickSheet(load: load, title: title),
  );
}

class _EquipmentPickSheet extends StatefulWidget {
  final Future<List<EquipmentOption>> Function() load;
  final String? title;
  const _EquipmentPickSheet({required this.load, this.title});

  @override
  State<_EquipmentPickSheet> createState() => _EquipmentPickSheetState();
}

class _EquipmentPickSheetState extends State<_EquipmentPickSheet> {
  List<EquipmentOption> _options = const [];
  EquipmentOption? _product;
  final Set<int> _selected = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final options = await widget.load();
      if (!mounted) return;
      setState(() {
        _options = options;
        // One product and nothing to choose inside it — pre-select, so the
        // manager isn't asked a question with a single answer.
        _product = options.length == 1 ? options.first : null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _selectProduct(EquipmentOption product) {
    setState(() {
      _product = product;
      _selected.clear();
    });
  }

  void _pick(OptionType axis, OptionValue value) {
    final product = _product!;
    setState(() {
      _selected.removeAll(axis.values.map((v) => v.id));
      _selected.add(value.id);
      for (final other in product.optionTypes) {
        if (other.id == axis.id) continue;
        final selectable = product.selectableValueIds(other, _selected);
        _selected.removeWhere(
          (id) =>
              other.values.any((v) => v.id == id) && !selectable.contains(id),
        );
      }
    });
  }

  /// What the preview shows: the picked combination's photo, else the first
  /// combination the picks so far lead to, else the product's catalogue cover.
  String _previewImage(EquipmentOption product) {
    final variant = product.variantFor(_selected);
    if (variant != null && variant.image.isNotEmpty) return variant.image;
    final narrowed = product.representativeImage(_selected);
    return narrowed.isNotEmpty ? narrowed : product.cover;
  }

  /// A complete pick, or null while anything is still unanswered.
  EquipmentPick? get _pickOrNull {
    final product = _product;
    if (product == null) return null;
    if (!product.needsVariant) return EquipmentPick(product: product);
    final variant = product.variantFor(_selected);
    return variant == null
        ? null
        : EquipmentPick(product: product, variant: variant);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pick = _pickOrNull;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            const SizedBox(height: 20),
            TextCustom.subheading(text: widget.title ?? l10n.approvePickModel),
            const SizedBox(height: 6),
            TextCustom(
              text: l10n.approveModelNote,
              fontSize: 12.5,
              color: context.colors.textSecondary,
            ),
            const SizedBox(height: 16),
            Flexible(child: _body(l10n)),
            const SizedBox(height: 16),
            ButtonCustom.primary(
              // The goal is the whole point of the choice — name it on the
              // button rather than leaving it to be discovered after approval.
              text: pick == null
                  ? l10n.approveButton
                  : l10n.approveWithTarget(pick.price),
              onPressed: pick == null
                  ? null
                  : () => Navigator.of(context).pop(pick),
            ),
            const SizedBox(height: 10),
            ButtonCustom.secondary(
              text: l10n.cancelButton,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    // The placeholder states fill whatever they're given, so cap them — a
    // spinner has no business stretching the sheet to full screen.
    if (_loading) {
      return const SizedBox(height: 160, child: LoadingView());
    }
    if (_error != null) {
      return SizedBox(
        height: 200,
        child: ErrorView(
          message: _error!,
          retryLabel: l10n.retry,
          onRetry: _load,
        ),
      );
    }
    if (_options.isEmpty) {
      return SizedBox(
        height: 200,
        child: EmptyView(
          message: l10n.dpNoModels,
          icon: Icons.kitchen_outlined,
        ),
      );
    }
    final product = _product;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_options.length > 1)
            for (final option in _options) ...[
              _ProductTile(
                option: option,
                selected: option.id == product?.id,
                onTap: () => _selectProduct(option),
              ),
              const SizedBox(height: 8),
            ],
          if (product != null) ...[
            const SizedBox(height: 4),
            // What is actually being approved, in one line — the manager
            // commits a specific unit at a specific price, and until now the
            // sheet showed only chips and a catalogue cover.
            _PickPreview(
              product: product,
              variant: product.variantFor(_selected),
              image: _previewImage(product),
            ),
          ],
          if (product != null && product.needsVariant)
            for (final axis in product.optionTypes) ...[
              const SizedBox(height: 8),
              _AxisRow(
                axis: axis,
                selected: _selected,
                selectable: product.selectableValueIds(axis, _selected),
                onPick: (value) => _pick(axis, value),
              ),
            ],
        ],
      ),
    );
  }
}

/// The current pick, shown above the axes: the photo narrows as the manager
/// chooses, the name reads as it will read in the request and the notification,
/// and the price range stands in until a combination fixes the goal. The photo
/// zooms on tap — the difference between two models is often a detail in the
/// picture, and the manager is committing money to it.
class _PickPreview extends StatelessWidget {
  final EquipmentOption product;
  final EquipmentVariant? variant;
  final String image;

  const _PickPreview({
    required this.product,
    required this.variant,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = variant;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ModelThumb(url: image, size: 64, zoomUrl: image),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: product.name,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                TextCustom(
                  // Before the pick there is no single price — the server's own
                  // range says what the goal will land between.
                  text: v != null
                      ? v.name
                      : product.priceFrom == product.priceTo
                      ? l10n.dpTargetAmount(product.priceFrom)
                      : l10n.dpTargetAmount(
                          '${product.priceFrom} – ${product.priceTo}',
                        ),
                  fontSize: 12.5,
                  fontWeight: v != null ? FontWeight.w700 : FontWeight.w400,
                  color: v != null
                      ? context.colors.primary
                      : context.colors.textSecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final EquipmentOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ProductTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? context.colors.primary : context.colors.border,
              width: selected ? 1.4 : 0.6,
            ),
          ),
          child: Row(
            children: [
              ModelThumb(url: option.cover),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      text: option.name,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    TextCustom(
                      text: option.priceFrom == option.priceTo
                          ? l10n.dpTargetAmount(option.priceFrom)
                          : l10n.dpTargetAmount(
                              '${option.priceFrom} – ${option.priceTo}',
                            ),
                      fontSize: 12.5,
                      color: context.colors.textSecondary,
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? context.colors.primary
                    : context.colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One axis of choice. A value with no available combination behind it renders
/// disabled, never hidden — the manager must see the whole matrix to explain a
/// rejection.
class _AxisRow extends StatelessWidget {
  final OptionType axis;
  final Set<int> selected;
  final Set<int> selectable;
  final ValueChanged<OptionValue> onPick;

  const _AxisRow({
    required this.axis,
    required this.selected,
    required this.selectable,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextCustom(
          text: axis.name,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in axis.values)
              _ValueChip(
                value: value,
                selected: selected.contains(value.id),
                enabled: selectable.contains(value.id),
                onTap: () => onPick(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _ValueChip extends StatelessWidget {
  final OptionValue value;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ValueChip({
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.colors.primary : context.colors.border,
              width: selected ? 1.4 : 0.6,
            ),
          ),
          child: TextCustom(
            text: value.value,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected
                ? context.colors.primary
                : context.colors.textPrimary,
            decoration: enabled ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}

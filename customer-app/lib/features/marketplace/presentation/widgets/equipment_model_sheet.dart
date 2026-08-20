import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/image_carousel.dart';
import 'package:sapbaq/core/widgets/sheet_header.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';
import 'package:sapbaq/features/products/data/models/product_option.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/marketplace_card.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Model detail — the photo gallery staff uploaded and the written specs, for a
/// donor deciding whether to back this campaign. The model itself is settled
/// (the regional manager fixed it at approval), so nothing here is a choice.
///
/// [funding] shows where the campaign stands and swaps the model's catalogue
/// price for the campaign goal — the price of one unit is no longer what any
/// single donor pays. Pass null to show the model on its own.
///
/// Resolves true when the customer wants to contribute.
Future<bool> showEquipmentModelSheet(
  BuildContext context, {
  required EquipmentListing listing,
}) async {
  final contribute = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // A quick look, not a page: the sheet grows only as tall as its content and
    // stops well short of the top, so the campaign list stays visible behind it
    // — and that strip doubles as the tap-to-dismiss target.
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (_) => _EquipmentModelSheet(listing: listing),
  );
  return contribute ?? false;
}

class _EquipmentModelSheet extends StatelessWidget {
  final EquipmentListing listing;
  const _EquipmentModelSheet({required this.listing});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final variant = listing.variant!;
    final funding = listing.funding;
    final specs = variant.attributesDisplay
        .where((a) => a.isRenderable)
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandleBar(),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    // Wider than tall on purpose: in a capped sheet a square
                    // gallery would leave no room for the goal and the specs,
                    // and `contain` keeps the whole unit visible either way.
                    child: ImageCarousel(
                      images: variant.gallery,
                      aspectRatio: 1.3,
                      padding: 16,
                      showThumbnails: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextCustom.subheading(text: listing.title),
                        const SizedBox(height: 10),
                        // In a campaign the unit price is the *goal*, split
                        // across donors — a bare price would read as the ask.
                        if (funding != null) ...[
                          TextCustom(
                            text: l10n.fundingGoal(funding.targetAmount),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: context.colors.primary,
                          ),
                          const SizedBox(height: 12),
                          FundingProgress(funding: funding),
                        ],
                        // What the mosque is getting, in the backend's wording.
                        if (specs.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _Specs(specs: specs),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pinned below the scroll area: on a long spec list the contribute
          // button would otherwise sit past the fold, out of reach.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: ButtonCustom.primary(
                text: funding != null ? l10n.contributeAction : l10n.contribute,
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The spec rows, in the backend's order: label on the leading side, value on
/// the trailing side, separated by hairlines.
class _Specs extends StatelessWidget {
  final List<ProductAttribute> specs;
  const _Specs({required this.specs});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            for (var i = 0; i < specs.length; i++) ...[
              if (i > 0) Divider(height: 1, color: context.colors.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextCustom(
                        text: specs[i].label,
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextCustom(
                      text: specs[i].value,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

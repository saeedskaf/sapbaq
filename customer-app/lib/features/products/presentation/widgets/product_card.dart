import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/image_carousel.dart';
import 'package:sapbaq/core/widgets/price_text.dart';
import 'package:sapbaq/features/products/data/models/product.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

const double _cardRadius = 18;

/// Saturation-zero matrix — greys out the photo of an unavailable product
/// without touching layout.
const ColorFilter _greyscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// Minimal product grid card (2 per row): tinted square frame for the image,
/// then a clean info block — name, one-line subtitle, and the price. The one
/// card for every "product seen from outside" surface (store grid, home shelf),
/// so the subtitle appears in all of them or in none.
/// Tapping the card opens the detail screen where the cart actions live.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badge = _discountBadge(l10n);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: context.colors.imageWell),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (product.isAvailable)
                        _image()
                      else
                        ColorFiltered(
                          colorFilter: _greyscale,
                          child: Opacity(opacity: 0.6, child: _image()),
                        ),
                      // A product you can't order right now shouldn't shout
                      // its discount.
                      if (badge != null && product.isAvailable)
                        PositionedDirectional(
                          top: 10,
                          start: 10,
                          child: _Badge(text: badge),
                        ),
                      // One quiet mark in the bottom corner: unavailability
                      // outranks the approval note; both live in the sheet.
                      if (!product.isAvailable)
                        PositionedDirectional(
                          bottom: 10,
                          start: 10,
                          child: _Badge(
                            text: l10n.notAvailableNow,
                            muted: true,
                          ),
                        )
                      else if (product.isApproval)
                        PositionedDirectional(
                          bottom: 10,
                          start: 10,
                          child: _Badge(
                            text: l10n.needsApprovalBadge,
                            muted: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 20,
                      child: TextCustom(
                        text: product.name,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // One line of the description, cut with an ellipsis exactly
                    // like the name above it. The row is reserved whether or not
                    // the text arrives, so every card in a row ends its price on
                    // the same line.
                    SizedBox(
                      height: 18,
                      child: TextCustom(
                        text: product.description.isEmpty
                            ? ' '
                            : product.description,
                        fontSize: 12,
                        color: context.colors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PriceRow(product: product, l10n: l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image() => ContainedImage(
    url: product.image,
    placeholderIcon: Icons.water_drop_outlined,
    placeholderSize: 36,
    padding: 14,
  );

  String? _discountBadge(AppLocalizations l10n) {
    if (!product.hasDiscount) return null;
    if (product.discountLabel != null && product.discountLabel!.isNotEmpty) {
      return product.discountLabel;
    }
    if (product.discountPercent != null) return '-${product.discountPercent}%';
    return null;
  }
}

/// Inline price + (optional) struck list price, both on the same line so all
/// cards share the same content height.
class _PriceRow extends StatelessWidget {
  final Product product;
  final AppLocalizations l10n;

  const _PriceRow({required this.product, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      // Baseline, not bottom: the two prices are different sizes, so aligning
      // their boxes left the smaller one floating and needed a hand-tuned
      // padding to look level.
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: TextCustom(
            // "from …" only when the range actually varies; the server owns
            // both ends, so nothing is derived from the (absent) variants here.
            text: product.hasPriceRange
                ? l10n.priceFromKwd(product.priceFrom)
                : l10n.priceKwd(product.priceFrom),
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.colors.primary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (product.hasDiscount) ...[
          const SizedBox(width: 6),
          // Deliberately outside the [Flexible] above: the list price is a
          // short number, so letting it take its natural width and squeezing
          // the live price instead would ellipsise the number that counts.
          StruckPrice(amount: product.price),
        ],
      ],
    );
  }
}

/// Small discount chip in the brand green — no extra shadows, no gold.
class _Badge extends StatelessWidget {
  final String text;

  /// A quiet variant for informational marks (the approval path) so they never
  /// compete with the discount badge.
  final bool muted;

  const _Badge({required this.text, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted ? context.colors.surface : context.colors.primaryFill,
        borderRadius: BorderRadius.circular(6),
        border: muted
            ? Border.all(color: context.colors.border, width: 0.8)
            : null,
      ),
      child: TextCustom(
        text: text,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: muted ? context.colors.primary : context.colors.onPrimary,
      ),
    );
  }
}

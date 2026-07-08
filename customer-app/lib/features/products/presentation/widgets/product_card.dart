import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/media_url.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/products/data/models/product.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

const double _cardRadius = 18;

/// Minimal product grid card (2 per row): tinted square frame for the image,
/// then a clean info block — name, single-line description, and the price.
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
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: _ProductImage(url: product.image),
                      ),
                      if (badge != null)
                        PositionedDirectional(
                          top: 10,
                          start: 10,
                          child: _Badge(text: badge),
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

  String? _discountBadge(AppLocalizations l10n) {
    if (!product.hasDiscount) return null;
    if (product.discountLabel != null && product.discountLabel!.isNotEmpty) {
      return product.discountLabel;
    }
    if (product.discountPercent != null) return '-${product.discountPercent}%';
    return null;
  }
}

/// Inline price + (optional) strike-through original price, both on the
/// same line so all cards share the same content height.
class _PriceRow extends StatelessWidget {
  final Product product;
  final AppLocalizations l10n;

  const _PriceRow({required this.product, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: TextCustom(
            text: l10n.priceKwd(product.effectivePrice),
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.colors.primary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (product.hasDiscount) ...[
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: TextCustom(
              text: product.price,
              fontSize: 11,
              color: context.colors.textHint,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}

/// Small discount chip in the brand green — no extra shadows, no gold.
class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.primaryFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextCustom(
        text: text,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: context.colors.onPrimary,
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;
  const _ProductImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(url);
    if (resolved == null) return const _ImageFallback();
    return Image.network(
      resolved,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.primary,
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.water_drop_outlined,
        size: 36,
        color: context.colors.textHint,
      ),
    );
  }
}

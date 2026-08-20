import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/image_carousel.dart';
import 'package:sapbaq/core/widgets/in_app_media.dart';

/// The one small product-photo tile: order lines, cart lines, marketplace
/// campaign cards, equipment requests — anywhere a product is referenced in a
/// row rather than presented in a gallery.
///
/// Always [BoxFit.contain] on the fixed-light [ThemeColors.imageWell]: a
/// cropped cooler is exactly the part of the photo the donor wanted to see,
/// and thumbnails are where cropping hurts most.
class ProductThumb extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;

  /// Breathing room so the contained photo doesn't touch the rounded corners.
  final double padding;

  final IconData placeholderIcon;

  /// When set, tapping opens the in-app zoom viewer on this URL (usually the
  /// full-size original; falls back to [url] call-side when there is none).
  final String? zoomUrl;

  const ProductThumb({
    super.key,
    required this.url,
    this.size = 48,
    this.radius = 10,
    this.padding = 4,
    this.placeholderIcon = Icons.water_drop_outlined,
    this.zoomUrl,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: context.colors.imageWell,
          child: ContainedImage(
            url: url,
            placeholderIcon: placeholderIcon,
            padding: padding,
            placeholderSize: size * 0.45,
          ),
        ),
      ),
    );
    if (zoomUrl == null) return tile;
    return GestureDetector(
      onTap: () => openInAppImage(context, url: zoomUrl!),
      child: tile,
    );
  }
}

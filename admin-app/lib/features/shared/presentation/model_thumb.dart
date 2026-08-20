import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/media_url.dart';
import 'package:sapbaq_admin/core/widgets/in_app_media.dart';

/// The one small product/model-photo tile: fulfilment tasks, contribution
/// rows, the equipment pick sheet — anywhere staff see what was funded.
///
/// Always [BoxFit.contain] on the fixed-light [ThemeColors.imageWell]: staff
/// approve and install the exact unit in the photo, and cropping lops off the
/// part being judged. Real photographs (settlements, maintenance, proofs)
/// stay full-bleed elsewhere — this tile is for catalogue shots only.
class ModelThumb extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;

  /// Breathing room so the contained photo doesn't touch the rounded corners.
  final double padding;

  final IconData placeholderIcon;

  /// When set, tapping opens the in-app zoom viewer on this URL (usually the
  /// full-size original behind a listing thumbnail).
  final String? zoomUrl;

  /// Preferred over [zoomUrl] when the tile stands for something with several
  /// photos — a variant's `images[]`. Tapping then opens the swipeable gallery,
  /// so staff see every angle of the unit without leaving the row.
  final List<String> zoomUrls;

  const ModelThumb({
    super.key,
    required this.url,
    this.size = 48,
    this.radius = 10,
    this.padding = 4,
    this.placeholderIcon = Icons.kitchen_rounded,
    this.zoomUrl,
    this.zoomUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(url);
    final placeholder = Center(
      child: Icon(
        placeholderIcon,
        size: size * 0.45,
        color: context.colors.textHint,
      ),
    );
    final tile = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: context.colors.imageWell,
          child: resolved == null
              ? placeholder
              : Padding(
                  padding: EdgeInsets.all(padding),
                  child: Image.network(
                    resolved,
                    fit: BoxFit.contain,
                    // Variant photos arrive full size — there is no server-side
                    // derivative for them (backend answers 2026-08-04 §2), and
                    // they run past 2 MB. Decode at tile size so a scrolling
                    // list holds thumbnails, not full bitmaps.
                    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                    errorBuilder: (_, _, _) => placeholder,
                  ),
                ),
        ),
      ),
    );
    if (zoomUrls.length > 1) {
      return GestureDetector(
        onTap: () => openInAppImageGallery(context, urls: zoomUrls),
        child: tile,
      );
    }
    final single = zoomUrl ?? (zoomUrls.isEmpty ? null : zoomUrls.first);
    if (single == null) return tile;
    return GestureDetector(
      onTap: () => openInAppImage(context, url: single),
      child: tile,
    );
  }
}

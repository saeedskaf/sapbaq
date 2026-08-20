import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/in_app_media.dart';

/// A horizontal strip of photo thumbnails — maintenance evidence, a
/// representative's report — where tapping one opens the whole strip in the
/// full-screen viewer, swipeable from photo to photo. Staff read these sets to
/// judge a case, so getting to the next photo must not mean closing this one and
/// finding the next thumbnail.
class PhotoStrip extends StatelessWidget {
  final List<String> urls;

  const PhotoStrip({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () =>
              openInAppImageGallery(context, urls: urls, initialIndex: i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              urls[i],
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              // Evidence photos come straight from a phone camera; decode them
              // at strip size rather than at capture size.
              cacheWidth: (64 * MediaQuery.devicePixelRatioOf(context)).round(),
              errorBuilder: (_, _, _) => Container(
                width: 64,
                height: 64,
                color: context.colors.surfaceVariant,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: context.colors.textHint,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

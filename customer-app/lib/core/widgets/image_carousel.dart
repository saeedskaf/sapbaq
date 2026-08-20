import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/media_url.dart';
import 'package:sapbaq/core/widgets/in_app_media.dart';

/// One entry in an [ImageCarousel]: a product photo, or a video shown through
/// its poster thumbnail.
class CarouselMedia {
  final String url;
  final bool isVideo;

  /// Poster frame for a video entry; images carry their own pixels.
  final String? thumbnail;

  const CarouselMedia.image(this.url) : isVideo = false, thumbnail = null;
  const CarouselMedia.video(this.url, {this.thumbnail}) : isVideo = true;
}

/// The swipeable product-media gallery used everywhere a product (or an
/// equipment model) is presented: the product detail sheet, the equipment
/// model sheet, and any future gallery.
///
/// Photos are fitted with [BoxFit.contain] on purpose: these are photographed
/// products — coolers, fridges, air conditioners — shot at whatever aspect the
/// supplier sent. Cropping to fill the frame lops off the top or the sides of
/// the unit, which is exactly the part the customer is trying to judge. They
/// sit on [ThemeColors.imageWell], the fixed-light photo well, so
/// white-background shots blend in both themes.
///
/// Videos show their poster under a play badge and open the in-app player;
/// photos open the in-app zoom viewer.
///
/// Page indication: animated pill dots by default, or a tappable thumbnail
/// strip when [showThumbnails] is set (the product sheet's choice — with
/// several photos and a video, jumping beats swiping blind).
class ImageCarousel extends StatefulWidget {
  /// Gallery entries, cover first. URLs may be relative — resolved here.
  final List<CarouselMedia> media;

  /// Shown when [media] is empty or an entry fails to load.
  final IconData placeholderIcon;

  /// Inset around each photo so a `contain` fit doesn't touch the rounded
  /// corners.
  final double padding;

  /// Frame shape of the gallery slot.
  final double aspectRatio;
  final double borderRadius;

  /// Overlay pinned to the top-start corner (the discount badge slot).
  final Widget? badge;

  /// Replace the dots with a strip of tappable thumbnails (needs > 1 entry).
  final bool showThumbnails;

  /// Photo-only convenience — the common case outside the product sheet.
  ImageCarousel({
    super.key,
    required List<String> images,
    this.placeholderIcon = Icons.kitchen_rounded,
    this.padding = 20,
    this.aspectRatio = 1,
    this.borderRadius = 18,
    this.badge,
    this.showThumbnails = false,
  }) : media = [for (final url in images) CarouselMedia.image(url)];

  const ImageCarousel.media({
    super.key,
    required this.media,
    this.placeholderIcon = Icons.kitchen_rounded,
    this.padding = 20,
    this.aspectRatio = 1,
    this.borderRadius = 18,
    this.badge,
    this.showThumbnails = false,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpTo(int index) {
    if (index == _page) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// Opens the full-screen viewer on the tapped photo and follows it: whichever
  /// photo the customer stops on there is the one this carousel shows when the
  /// viewer closes, so the two never disagree.
  Future<void> _openViewer(
    BuildContext context, {
    required List<String> photos,
    required List<int> pageOfPhoto,
    required int photoIndex,
  }) async {
    var last = photoIndex;
    await openInAppImageGallery(
      context,
      urls: photos,
      initialIndex: photoIndex,
      onPageChanged: (i) => last = i,
    );
    if (!mounted || last == photoIndex || !_controller.hasClients) return;
    _controller.jumpToPage(pageOfPhoto[last]);
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    // Every photo of this gallery, and the mapping both ways, so opening one
    // photo opens all of them: the viewer swipes between them instead of
    // sending the customer back here for the next one. Videos keep their own
    // player, so they are not part of the photo run (-1).
    final photos = <String>[];
    final photoIndexes = <int>[]; // page → photo
    final pageOfPhoto = <int>[]; // photo → page
    for (var i = 0; i < media.length; i++) {
      final isVideo = media[i].isVideo;
      photoIndexes.add(isVideo ? -1 : photos.length);
      if (isVideo) continue;
      pageOfPhoto.add(i);
      photos.add(media[i].url);
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: ColoredBox(
              color: context.colors.imageWell,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (media.isEmpty)
                    _Placeholder(icon: widget.placeholderIcon)
                  else
                    PageView.builder(
                      controller: _controller,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemCount: media.length,
                      itemBuilder: (pageContext, i) => _MediaPage(
                        media: media[i],
                        onOpenPhoto: () => _openViewer(
                          pageContext,
                          photos: photos,
                          pageOfPhoto: pageOfPhoto,
                          photoIndex: photoIndexes[i],
                        ),
                        padding: widget.padding,
                        placeholderIcon: widget.placeholderIcon,
                      ),
                    ),
                  if (widget.badge != null)
                    PositionedDirectional(
                      top: 14,
                      start: 14,
                      child: widget.badge!,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (media.length > 1) ...[
          const SizedBox(height: 12),
          if (widget.showThumbnails)
            _ThumbStrip(
              media: media,
              selected: _page,
              placeholderIcon: widget.placeholderIcon,
              onTap: _jumpTo,
            )
          else
            _Dots(count: media.length, selected: _page),
        ],
      ],
    );
  }
}

/// Animated pill dots — one per page, the active one stretched.
class _Dots extends StatelessWidget {
  final int count;
  final int selected;

  const _Dots({required this.count, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == selected ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == selected
                  ? context.colors.primary
                  : context.colors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// Centered row of tappable page thumbnails; the visible page is ringed.
class _ThumbStrip extends StatelessWidget {
  final List<CarouselMedia> media;
  final int selected;
  final IconData placeholderIcon;
  final ValueChanged<int> onTap;

  const _ThumbStrip({
    required this.media,
    required this.selected,
    required this.placeholderIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Center short strips; long ones scroll from the start edge.
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: media.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _Thumbnail(
          media: media[i],
          selected: i == selected,
          placeholderIcon: placeholderIcon,
          onTap: () => onTap(i),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final CarouselMedia media;
  final bool selected;
  final IconData placeholderIcon;
  final VoidCallback onTap;

  const _Thumbnail({
    required this.media,
    required this.selected,
    required this.placeholderIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(
      media.isVideo ? media.thumbnail : media.url,
    );
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.colors.imageWell,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (resolved == null)
              _Placeholder(icon: placeholderIcon, size: 20)
            else
              Padding(
                // Videos keep their poster full-bleed; photos stay contained.
                padding: EdgeInsets.all(media.isVideo ? 0 : 4),
                child: Image.network(
                  resolved,
                  fit: media.isVideo ? BoxFit.cover : BoxFit.contain,
                  cacheWidth: (52 * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  errorBuilder: (_, _, _) =>
                      _Placeholder(icon: placeholderIcon, size: 20),
                ),
              ),
            if (media.isVideo) const Center(child: PlayBadge(size: 22)),
          ],
        ),
      ),
    );
  }
}

/// One gallery page: a contained photo that opens the swipeable zoom viewer over
/// [photos], or a video poster under a play badge that opens the in-app player.
class _MediaPage extends StatelessWidget {
  final CarouselMedia media;

  /// Opens the host carousel's photo run at this page. Unused on a video page,
  /// which has its own player.
  final VoidCallback onOpenPhoto;
  final double padding;
  final IconData placeholderIcon;

  const _MediaPage({
    required this.media,
    required this.onOpenPhoto,
    required this.padding,
    required this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (media.isVideo) {
      final poster = resolveMediaUrl(media.thumbnail);
      return GestureDetector(
        onTap: () => openInAppVideo(context, media.url),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (poster != null)
              Image.network(
                poster,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const MediaFallback(isVideo: true),
              )
            else
              const MediaFallback(isVideo: true),
            const Center(child: PlayBadge()),
          ],
        ),
      );
    }

    final resolved = resolveMediaUrl(media.url);
    if (resolved == null) return _Placeholder(icon: placeholderIcon);
    return GestureDetector(
      onTap: onOpenPhoto,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.network(
          resolved,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.primary,
              ),
            );
          },
          errorBuilder: (_, _, _) => _Placeholder(icon: placeholderIcon),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final double size;
  const _Placeholder({required this.icon, this.size = 56});

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size, color: context.colors.textHint);
}

/// A single photo sized to fill a card slot, fitted with [BoxFit.contain] for
/// the same reason as [ImageCarousel] — the whole unit stays visible.
class ContainedImage extends StatelessWidget {
  final String? url;
  final IconData placeholderIcon;
  final double padding;

  /// Placeholder icon size — pass something small in compact thumbnails.
  final double placeholderSize;

  const ContainedImage({
    super.key,
    required this.url,
    this.placeholderIcon = Icons.kitchen_rounded,
    this.padding = 10,
    this.placeholderSize = 56,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(url);
    if (resolved == null) {
      return _Placeholder(icon: placeholderIcon, size: placeholderSize);
    }
    // Every use of this widget is a small fixed slot — a cart line, an option
    // chip, a card thumbnail — while the photos behind it are full-size product
    // shots (variant images run past 2 MB; the server keeps no derivative).
    // Decode to the slot it is painted in.
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsets.all(padding),
        child: Image.network(
          resolved,
          fit: BoxFit.contain,
          cacheWidth: constraints.maxWidth.isFinite
              ? (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                    .round()
              : null,
          loadingBuilder: (_, child, progress) {
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
          errorBuilder: (_, _, _) =>
              _Placeholder(icon: placeholderIcon, size: placeholderSize),
        ),
      ),
    );
  }
}

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/media_url.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';

/// In-app media viewers shared by the product gallery, the showcase tab, and
/// delivery proofs. Nothing here hands off to an external player or browser:
/// images zoom in a dialog, videos play in a full-screen Chewie player. Both
/// entry points resolve the path via [resolveMediaUrl], so callers can pass the
/// raw API field directly.

/// Opens [url] (an image) in a full-screen viewer with an optional [caption].
/// Pinch zooms freely and double-tap toggles zoom in/out. No-op when [url] is
/// null/empty.
Future<void> openInAppImage(
  BuildContext context, {
  required String? url,
  String? caption,
}) {
  final resolved = resolveMediaUrl(url);
  if (resolved == null) return Future<void>.value();
  return showDialog<void>(
    context: context,
    barrierColor: ColorsCustom.scrimHeavy,
    builder: (_) => _ImageViewer(url: resolved, caption: caption),
  );
}

/// Opens a swipeable full-screen gallery over [urls], starting at
/// [initialIndex]. Every page zooms exactly like [openInAppImage]; swiping to
/// the neighbouring page is locked while the current one is zoomed in.
/// [captions] runs parallel to [urls]. Unresolvable URLs are skipped; a no-op
/// when nothing resolves.
///
/// [onPageChanged] reports the viewed photo as an index **into [urls]** (skipped
/// entries never surface), so a host gallery can follow along and stay on the
/// photo the viewer was closed on.
Future<void> openInAppImageGallery(
  BuildContext context, {
  required List<String> urls,
  int initialIndex = 0,
  List<String?>? captions,
  ValueChanged<int>? onPageChanged,
}) {
  final pages = <({String url, String? caption, int source})>[];
  var start = 0;
  for (var i = 0; i < urls.length; i++) {
    final resolved = resolveMediaUrl(urls[i]);
    if (resolved == null) continue;
    if (i == initialIndex) start = pages.length;
    pages.add((
      url: resolved,
      caption: captions != null && i < captions.length ? captions[i] : null,
      source: i,
    ));
  }
  if (pages.isEmpty) return Future<void>.value();
  // A transparent fade route on the root navigator (not a dialog): it covers
  // the whole shell — floating nav bar included — like the video player does.
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (_, _, _) => _GalleryViewer(
        pages: pages,
        initialIndex: start,
        onPageChanged: onPageChanged,
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Opens [url] (a video) in a full-screen in-app player. Shows an error message
/// when the URL is missing.
Future<void> openInAppVideo(BuildContext context, String? url) {
  final resolved = resolveMediaUrl(url);
  if (resolved == null) {
    ShowMessage.error(context, AppLocalizations.of(context)!.cannotOpenFile);
    return Future<void>.value();
  }
  // Root navigator so the player covers the whole app — including the shell's
  // floating nav bar and cart bar — while the video plays.
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _VideoPlayerScreen(url: resolved),
    ),
  );
}

class _ImageViewer extends StatelessWidget {
  final String url;
  final String? caption;

  const _ImageViewer({required this.url, this.caption});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _CloseButton(scrim: true),
          ),
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _ZoomableImage(url: url),
            ),
          ),
          if (caption != null && caption!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CaptionChip(text: caption!),
          ],
        ],
      ),
    );
  }
}

/// The caption pill shown under a viewed image.
class _CaptionChip extends StatelessWidget {
  final String text;

  const _CaptionChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ColorsCustom.scrim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextCustom(
        text: text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Pinch/double-tap zoomable image — the shared body of the single viewer and
/// every gallery page. Pinch zooms between the fitted size and [_maxScale];
/// double-tap toggles between fit and [_doubleTapScale], anchored on the
/// tapped point so the spot under the finger stays in view. Reports zoom-state
/// flips through [onZoomChanged] so a host [PageView] can lock swiping while
/// the image is zoomed.
class _ZoomableImage extends StatefulWidget {
  /// Already-resolved URL.
  final String url;
  final ValueChanged<bool>? onZoomChanged;

  const _ZoomableImage({required this.url, this.onZoomChanged});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage>
    with SingleTickerProviderStateMixin {
  static const double _maxScale = 5;
  static const double _doubleTapScale = 2.5;

  final TransformationController _transform = TransformationController();
  // Created eagerly in initState (not a lazy `late final`): the controller's
  // ticker reads an inherited widget (TickerMode) via `context`. Deferring
  // creation until first use would fire that lookup inside dispose() when the
  // image is opened and closed without ever double-tap-zooming, throwing
  // "Looking up a deactivated widget's ancestor is unsafe".
  late final AnimationController _zoomAnimation;
  Animation<Matrix4>? _zoomFrames;
  Offset _doubleTapPosition = Offset.zero;
  bool _reportedZoomed = false;

  @override
  void initState() {
    super.initState();
    _zoomAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(_applyZoomFrame);
    _transform.addListener(_reportZoom);
  }

  @override
  void dispose() {
    _zoomAnimation.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _reportZoom() {
    // The 1.01 tolerance absorbs float drift from pinch gestures that ended
    // back at the fitted size.
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _reportedZoomed) return;
    _reportedZoomed = zoomed;
    widget.onZoomChanged?.call(zoomed);
  }

  void _applyZoomFrame() {
    final frames = _zoomFrames;
    if (frames != null) _transform.value = frames.value;
  }

  void _animateZoomTo(Matrix4 target) {
    _zoomFrames = Matrix4Tween(begin: _transform.value, end: target).animate(
      CurvedAnimation(parent: _zoomAnimation, curve: Curves.easeOutCubic),
    );
    _zoomAnimation.forward(from: 0);
  }

  void _onDoubleTap() {
    final zoomedIn = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomedIn) {
      _animateZoomTo(Matrix4.identity());
      return;
    }
    // Scale about the tapped point: shift it back so it stays put while the
    // image grows around it. Any point inside the viewport yields an
    // in-bounds transform, so no clamping is needed.
    final p = _doubleTapPosition;
    const s = _doubleTapScale;
    _animateZoomTo(
      Matrix4.identity()
        ..translateByDouble(-p.dx * (s - 1), -p.dy * (s - 1), 0, 1)
        ..scaleByDouble(s, s, 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: _maxScale,
        onInteractionStart: (_) => _zoomAnimation.stop(),
        child: Image.network(
          widget.url,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: ColorsCustom.glassEdge),
            );
          },
          errorBuilder: (_, _, _) => const MediaFallback(isVideo: false),
        ),
      ),
    );
  }
}

/// Swipeable full-screen image gallery: one zoomable page per image, a small
/// «3/12» position chip, and the page's caption underneath. Swiping is locked
/// while the current page is zoomed so panning the enlarged image never flips
/// the page.
class _GalleryViewer extends StatefulWidget {
  final List<({String url, String? caption, int source})> pages;
  final int initialIndex;
  final ValueChanged<int>? onPageChanged;

  const _GalleryViewer({
    required this.pages,
    required this.initialIndex,
    this.onPageChanged,
  });

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onZoomChanged(bool zoomed) {
    if (zoomed == _zoomed) return;
    setState(() => _zoomed = zoomed);
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.pages[_index].caption;
    return Material(
      color: ColorsCustom.scrimHeavy,
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  if (widget.pages.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextCustom(
                        text: '${_index + 1}/${widget.pages.length}',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  const Spacer(),
                  // Scrimmed like the video player's: the bar sits above the
                  // photo, but a bright edge-to-edge shot must never leave the
                  // way out hard to find.
                  const _CloseButton(scrim: true),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: _zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _index = i);
                  widget.onPageChanged?.call(widget.pages[i].source);
                },
                itemCount: widget.pages.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ZoomableImage(
                    url: widget.pages[i].url,
                    onZoomChanged: _onZoomChanged,
                  ),
                ),
              ),
            ),
            if (caption != null && caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: _CaptionChip(text: caption),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen player. Builds the [VideoPlayerController] and [ChewieController]
/// only after [VideoPlayerController.initialize] succeeds, and disposes both on
/// close so no decoder keeps running in the background.
class _VideoPlayerScreen extends StatefulWidget {
  final String url;

  const _VideoPlayerScreen({required this.url});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final video = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await video.initialize();
    } catch (_) {
      await video.dispose();
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) {
      await video.dispose();
      return;
    }
    setState(() {
      _video = video;
      _chewie = ChewieController(
        videoPlayerController: video,
        autoPlay: true,
        looping: false,
        aspectRatio: video.value.aspectRatio,
        // No 3-dot options menu — it collides with our close button and its
        // speed/subtitle options add nothing for short clips.
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: context.colors.primary,
          handleColor: context.colors.primary,
          bufferedColor: Colors.white30,
          backgroundColor: Colors.white24,
        ),
      );
    });
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // SafeArea + a minimum inset keep the player, its controls, and the close
      // button clear of the edges and any notch/home-indicator on every device.
      body: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(child: _content()),
            const Align(
              alignment: Alignment.topCenter,
              child: _CloseButton(scrim: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (_failed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: ColorsCustom.glassEdge,
            size: 48,
          ),
          const SizedBox(height: 12),
          TextCustom(
            text: AppLocalizations.of(context)!.cannotOpenFile,
            color: Colors.white70,
            fontSize: 14,
          ),
        ],
      );
    }
    final chewie = _chewie;
    if (chewie == null) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return Chewie(controller: chewie);
  }
}

/// Close (X) for the full-screen viewers. [scrim] adds a dark circular backdrop
/// so it stays legible over bright media.
class _CloseButton extends StatelessWidget {
  final bool scrim;

  const _CloseButton({this.scrim = false});

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
      onPressed: () => Navigator.of(context).maybePop(),
    );
    if (!scrim) return button;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ColorsCustom.scrim,
        shape: BoxShape.circle,
      ),
      child: button,
    );
  }
}

/// White circular play badge with a black glyph — the tap affordance centered
/// on a video thumbnail. Both colours are fixed in either theme, like
/// [ColorsCustom.imageWell]: the badge sits on media rather than on a theme
/// surface, so a glyph following the theme would go white-on-white in dark.
class PlayBadge extends StatelessWidget {
  final double size;

  const PlayBadge({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: ColorsCustom.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ColorsCustom.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: ColorsCustom.black,
        size: size * 0.58,
      ),
    );
  }
}

/// Neutral icon shown when a thumbnail is missing or fails to load.
class MediaFallback extends StatelessWidget {
  final bool isVideo;
  final double size;

  const MediaFallback({super.key, required this.isVideo, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        size: size,
        color: context.colors.textHint,
      ),
    );
  }
}

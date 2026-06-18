import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/media_url.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

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
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (_) => _ImageViewer(url: resolved, caption: caption),
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

class _ImageViewer extends StatefulWidget {
  final String url;
  final String? caption;

  const _ImageViewer({required this.url, this.caption});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

/// Zoomable image body of the viewer. Pinch zooms between the fitted size and
/// [_maxScale]; double-tap toggles between fit and [_doubleTapScale], anchored
/// on the tapped point so the spot under the finger stays in view.
class _ImageViewerState extends State<_ImageViewer>
    with SingleTickerProviderStateMixin {
  static const double _maxScale = 5;
  static const double _doubleTapScale = 2.5;

  final TransformationController _transform = TransformationController();
  late final AnimationController _zoomAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..addListener(_applyZoomFrame);
  Animation<Matrix4>? _zoomFrames;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void dispose() {
    _zoomAnimation.dispose();
    _transform.dispose();
    super.dispose();
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
    // The 1.01 tolerance absorbs float drift from pinch gestures that ended
    // back at the fitted size.
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
    final caption = widget.caption;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _CloseButton(),
          ),
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onDoubleTapDown: (details) =>
                    _doubleTapPosition = details.localPosition,
                onDoubleTap: _onDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: _maxScale,
                  onInteractionStart: (_) => _zoomAnimation.stop(),
                  child: Image.network(
                    widget.url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const MediaFallback(isVideo: false),
                  ),
                ),
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextCustom(
                text: caption,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ],
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
            color: Colors.white54,
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
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: button,
    );
  }
}

/// White circular play badge with the brand-green glyph — the tap affordance
/// centered on a video thumbnail.
class PlayBadge extends StatelessWidget {
  final double size;

  const PlayBadge({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: context.colors.primary,
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

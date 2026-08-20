import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/media_url.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq/core/widgets/in_app_media.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/showcase/data/models/showcase_item.dart';
import 'package:sapbaq/features/showcase/data/models/showcase_section.dart';
import 'package:sapbaq/features/showcase/data/showcase_repository.dart';
import 'package:sapbaq/features/showcase/presentation/bloc/showcase_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Horizontal page padding for the gallery, and the gap between grid tiles.
const double _kPagePadding = 16;
const double _kGridSpacing = 10;

class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) =>
          ShowcaseCubit(context.read<ShowcaseRepository>())..load(),
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          backgroundColor: context.colors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: TextCustom(
            text: l10n.navMedia,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        body: BlocBuilder<ShowcaseCubit, ShowcaseState>(
          builder: (context, state) {
            switch (state.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const _SkeletonGallery();
              case LoadStatus.failure:
                return ErrorView(
                  message: state.message ?? l10n.comingSoon,
                  retryLabel: l10n.retry,
                  onRetry: () => context.read<ShowcaseCubit>().load(),
                );
              case LoadStatus.success:
                if (state.isEmpty) {
                  return EmptyView(
                    message: l10n.emptyMedia,
                    icon: Icons.collections_outlined,
                  );
                }
                return _Gallery(sections: state.sections);
            }
          },
        ),
      ),
    );
  }
}

/// An Instagram-style gallery: each non-empty section shows a header (title +
/// item count) followed by a uniform 2-column grid of media thumbnails.
class _Gallery extends StatelessWidget {
  final List<ShowcaseSection> sections;

  const _Gallery({required this.sections});

  @override
  Widget build(BuildContext context) {
    final visible = sections.where((s) => s.items.isNotEmpty).toList();
    // Decode thumbnails at tile size, not photo size — a media grid is where
    // full-resolution decodes cost the most memory and scroll smoothness.
    final tileWidth =
        (MediaQuery.sizeOf(context).width - _kPagePadding * 2 - _kGridSpacing) /
        2;
    final cacheWidth = (tileWidth * MediaQuery.devicePixelRatioOf(context))
        .round();
    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: () => context.read<ShowcaseCubit>().load(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          for (final (index, section) in visible.indexed) ...[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                _kPagePadding,
                index == 0 ? 12 : 28,
                _kPagePadding,
                12,
              ),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(section: section),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: _kPagePadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: _kGridSpacing,
                  mainAxisSpacing: _kGridSpacing,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _MediaTile(
                    item: section.items[i],
                    section: section,
                    cacheWidth: cacheWidth,
                  ),
                  childCount: section.items.length,
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: SizedBox(height: floatingNavBarClearance(context)),
          ),
        ],
      ),
    );
  }
}

/// First-load placeholder: a pulsing sketch of the gallery's real structure —
/// a header stub over grey tiles — instead of a lone spinner. Shows nothing
/// but shape.
class _SkeletonGallery extends StatefulWidget {
  const _SkeletonGallery();

  @override
  State<_SkeletonGallery> createState() => _SkeletonGalleryState();
}

class _SkeletonGalleryState extends State<_SkeletonGallery>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: 0.45,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = BoxDecoration(
      color: context.colors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
    );
    return FadeTransition(
      opacity: _pulse,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_kPagePadding, 12, _kPagePadding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 20,
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: _kGridSpacing,
                mainAxisSpacing: _kGridSpacing,
                children: [
                  for (var i = 0; i < 6; i++) DecoratedBox(decoration: block),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section title with a thin accent rule and the number of items it holds.
class _SectionHeader extends StatelessWidget {
  final ShowcaseSection section;

  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextCustom(
            text: section.title,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextCustom(
            text: l10n.mediaCount(section.items.length),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// A single square gallery tile: thumbnail only, with a play badge for videos.
/// A photo opens the swipeable gallery over its whole section; a video opens
/// the in-app player directly. Thumbnails fade in as they arrive and are
/// decoded at tile size ([cacheWidth]).
class _MediaTile extends StatefulWidget {
  final ShowcaseItem item;
  final ShowcaseSection section;
  final int cacheWidth;

  const _MediaTile({
    required this.item,
    required this.section,
    required this.cacheWidth,
  });

  @override
  State<_MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<_MediaTile> {
  bool _pressed = false;

  void _open(BuildContext context) {
    final item = widget.item;
    if (item.isVideo) {
      openInAppVideo(context, item.file);
      return;
    }
    // Swipe through the section's photos from this one; videos keep their own
    // player and stay out of the pager.
    final images = [
      for (final m in widget.section.items)
        if (!m.isVideo) m,
    ];
    final index = images.indexOf(item);
    openInAppImageGallery(
      context,
      urls: [for (final m in images) m.file],
      initialIndex: index < 0 ? 0 : index,
      captions: [for (final m in images) m.title],
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final url = resolveMediaUrl(item.isVideo ? item.thumbnail : item.file);
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: context.colors.surfaceVariant,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _open(context),
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url != null)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    cacheWidth: widget.cacheWidth,
                    // Fade in on arrival — the tinted tile is placeholder
                    // enough; a grid of spinners it is not.
                    frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: child,
                      );
                    },
                    errorBuilder: (_, _, _) =>
                        MediaFallback(isVideo: item.isVideo),
                  )
                else
                  MediaFallback(isVideo: item.isVideo),
                if (item.isVideo) const Center(child: PlayBadge(size: 44)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

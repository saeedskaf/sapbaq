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
import 'package:sapbaq/features/showcase/data/showcase_repository.dart';
import 'package:sapbaq/features/showcase/presentation/bloc/showcase_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// "الوسائط" tab — a public gallery of admin-uploaded photos/videos of
/// charity work, grouped into titled sections (FLUTTER_TASKS item 14). Each
/// section renders a header followed by a uniform 2-column grid of
/// cover-filled tiles. A title (when present) sits in a soft gradient caption
/// over the image, and videos carry a play badge. Tapping opens the full,
/// uncropped media: images in an in-app zoom viewer, videos in an in-app
/// player.
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
          iconTheme: IconThemeData(color: context.colors.textPrimary),
        ),
        body: BlocBuilder<ShowcaseCubit, ShowcaseState>(
          builder: (context, state) {
            switch (state.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const LoadingView();
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
                return RefreshIndicator(
                  color: context.colors.primary,
                  onRefresh: () => context.read<ShowcaseCubit>().load(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      for (final (i, section) in state.sections.indexed)
                        if (section.items.isNotEmpty) ...[
                          SliverPadding(
                            // Extra top space before every section after the
                            // first, so each titled block reads as its own group.
                            padding: EdgeInsets.fromLTRB(16, i == 0 ? 12 : 28, 16, 12),
                            sliver: SliverToBoxAdapter(
                              child: _SectionHeader(
                                title: section.title,
                                description: section.description,
                                count: section.items.length,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    // Uniform square tiles for a clean grid.
                                    childAspectRatio: 1,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) =>
                                    _ShowcaseCard(item: section.items[i]),
                                childCount: section.items.length,
                              ),
                            ),
                          ),
                        ],
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: floatingNavBarClearance(context),
                        ),
                      ),
                    ],
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

/// Section header above each grid block: a brand accent bar and title, a media
/// count chip, and an optional description. The accent bar + count chip give
/// each section a clear visual identity so the grouped structure reads at a
/// glance.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String description;
  final int count;
  const _SectionHeader({
    required this.title,
    required this.description,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Brand accent bar marking the start of the section.
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
                text: title,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            _CountChip(count: count),
          ],
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            // Align the description under the title, past the accent bar.
            padding: const EdgeInsetsDirectional.only(start: 14),
            child: TextCustom(
              text: description,
              fontSize: 12.5,
              color: context.colors.textSecondary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// A small rounded pill showing how many items a section holds — reinforces
/// each section's presence and size.
class _CountChip extends StatelessWidget {
  final int count;
  const _CountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primaryTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.collections_outlined,
            size: 13,
            color: context.colors.primary,
          ),
          const SizedBox(width: 5),
          TextCustom(
            text: '$count',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.colors.primary,
          ),
        ],
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  final ShowcaseItem item;
  const _ShowcaseCard({required this.item});

  void _onTap(BuildContext context) {
    if (item.isVideo) {
      openInAppVideo(context, item.file);
    } else {
      openInAppImage(context, url: item.file, caption: item.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: context.colors.surfaceVariant,
        child: InkWell(
          onTap: () => _onTap(context),
          child: _ShowcasePreview(item: item),
        ),
      ),
    );
  }
}

/// The media for one tile: the image/thumbnail rendered `BoxFit.cover` so every
/// tile fills uniformly. A title (when present) reads over a soft gradient
/// scrim at the bottom, and videos carry a centered play badge. The full,
/// uncropped media is shown in the viewer on tap.
class _ShowcasePreview extends StatelessWidget {
  final ShowcaseItem item;
  const _ShowcasePreview({required this.item});

  @override
  Widget build(BuildContext context) {
    // Video preview uses the thumbnail; image preview uses the file itself.
    final url = resolveMediaUrl(item.isVideo ? item.thumbnail : item.file);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url != null)
          Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
            errorBuilder: (_, _, _) => MediaFallback(isVideo: item.isVideo),
          )
        else
          MediaFallback(isVideo: item.isVideo),
        if (item.title.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xD9000000), Color(0x00000000)],
                ),
              ),
              child: TextCustom(
                text: item.title,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        if (item.isVideo) const Center(child: PlayBadge()),
      ],
    );
  }
}

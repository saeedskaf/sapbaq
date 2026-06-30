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
/// charity work, laid out as a clean, uniform 2-column grid of cover-filled
/// tiles. A title (when present) sits in a soft gradient caption over the
/// image, and videos carry a play badge. Tapping opens the full, uncropped
/// media: images in an in-app zoom viewer, videos in an in-app player.
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
                if (state.items.isEmpty) {
                  return EmptyView(
                    message: l10n.emptyMedia,
                    icon: Icons.collections_outlined,
                  );
                }
                return RefreshIndicator(
                  color: context.colors.primary,
                  onRefresh: () => context.read<ShowcaseCubit>().load(),
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      floatingNavBarClearance(context),
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          // Uniform square tiles for a clean, even gallery.
                          childAspectRatio: 1,
                        ),
                    itemCount: state.items.length,
                    itemBuilder: (context, i) =>
                        _ShowcaseCard(item: state.items[i]),
                  ),
                );
            }
          },
        ),
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

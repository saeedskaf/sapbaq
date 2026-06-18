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
/// charity work. Each item shows the whole image/thumbnail (no cropping) on a
/// soft rounded tile with its title beneath, so portrait and landscape media
/// both read correctly. Images open in an in-app zoom viewer; videos play in
/// an in-app player.
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
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          // Soft tile + one-line title → uniform cells.
                          childAspectRatio: 0.84,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: context.colors.surfaceVariant,
              child: InkWell(
                onTap: () => _onTap(context),
                child: _ShowcasePreview(item: item),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 18,
          child: TextCustom(
            text: item.title.isEmpty ? ' ' : item.title,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The media for one tile: the whole image/thumbnail rendered with
/// `BoxFit.contain` (no cropping), with a play badge over videos. The soft
/// tile background is supplied by the parent card.
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
            fit: BoxFit.contain,
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
        if (item.isVideo) const Center(child: PlayBadge()),
      ],
    );
  }
}

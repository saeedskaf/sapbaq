import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/models/mosque_filters.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';
import 'package:sapbaq/features/mosques/presentation/bloc/mosque_browse_cubit.dart';
import 'package:sapbaq/features/mosques/presentation/widgets/mosque_card.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The shared way to reach a mosque anywhere in the app: search at the top, and
/// below it a governorate → area → mosques drill-down. Typing a search
/// short-circuits the drill-down and shows matching mosques directly.
///
/// Used by the mosques list tab (rows open the mosque detail) and by the
/// donation destination picker (rows pop with the chosen mosque), so both walk
/// the same levels in the same order. Owns its own [MosqueBrowseCubit]; only a
/// [MosquesRepository] needs to be available above it.
class MosqueBrowseView extends StatelessWidget {
  /// Called when a mosque row is tapped.
  final ValueChanged<Mosque> onMosqueTap;

  /// Trailing widget for each mosque row (favourite toggle, pick indicator…).
  final Widget Function(Mosque mosque)? trailingBuilder;

  /// Extra bottom padding for the scrollables (e.g. the floating nav bar).
  final double bottomPadding;

  /// Optional banner under the search field — used by the mosques tab for the
  /// "most needed" shortcut. Hidden while a search is running, so it never
  /// sits on top of results.
  final Widget? header;

  const MosqueBrowseView({
    super.key,
    required this.onMosqueTap,
    this.trailingBuilder,
    this.bottomPadding = 24,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MosqueBrowseCubit(context.read<MosquesRepository>())..start(),
      child: _MosqueBrowseBody(
        onMosqueTap: onMosqueTap,
        trailingBuilder: trailingBuilder,
        bottomPadding: bottomPadding,
        header: header,
      ),
    );
  }
}

class _MosqueBrowseBody extends StatefulWidget {
  final ValueChanged<Mosque> onMosqueTap;
  final Widget Function(Mosque mosque)? trailingBuilder;
  final double bottomPadding;
  final Widget? header;

  const _MosqueBrowseBody({
    required this.onMosqueTap,
    required this.trailingBuilder,
    required this.bottomPadding,
    this.header,
  });

  @override
  State<_MosqueBrowseBody> createState() => _MosqueBrowseBodyState();
}

class _MosqueBrowseBodyState extends State<_MosqueBrowseBody>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {}); // refresh the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<MosqueBrowseCubit>().search(query);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    context.read<MosqueBrowseCubit>().search('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: FormFieldCustom(
            controller: _searchController,
            hintText: l10n.searchMosqueHint,
            isRequired: false,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _clearSearch,
                  )
                : null,
            onChanged: _onSearchChanged,
          ),
        ),
        if (widget.header != null && _searchController.text.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: widget.header!,
          ),
        Expanded(
          child: BlocBuilder<MosqueBrowseCubit, MosqueBrowseState>(
            builder: (context, state) {
              switch (state.status) {
                case LoadStatus.initial:
                case LoadStatus.loading:
                  return const LoadingView();
                case LoadStatus.failure:
                  return ErrorView(
                    message: state.message ?? l10n.comingSoon,
                    retryLabel: l10n.retry,
                    onRetry: () => context.read<MosqueBrowseCubit>().retry(),
                  );
                case LoadStatus.success:
                  if (state.isSearching ||
                      state.step == MosqueBrowseStep.mosques) {
                    return _MosqueResultsList(
                      state: state,
                      onMosqueTap: widget.onMosqueTap,
                      trailingBuilder: widget.trailingBuilder,
                      bottomPadding: widget.bottomPadding,
                    );
                  }
                  return _FacetList(
                    state: state,
                    bottomPadding: widget.bottomPadding,
                  );
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Breadcrumb + back control shown above the area and mosque levels.
class _BrowseHeader extends StatelessWidget {
  final MosqueBrowseState state;
  const _BrowseHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final crumbs = <String>[
      if (state.governorate != null) state.governorate!,
      if (state.area != null) state.area!,
    ];
    return Material(
      color: context.colors.surfaceVariant,
      child: InkWell(
        onTap: () => context.read<MosqueBrowseCubit>().back(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: context.colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextCustom(
                  text: crumbs.join('  •  '),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The governorate / area picker level: a titled list of facet rows.
class _FacetList extends StatelessWidget {
  final MosqueBrowseState state;
  final double bottomPadding;
  const _FacetList({required this.state, required this.bottomPadding});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGovernorate = state.step == MosqueBrowseStep.governorate;
    final title = isGovernorate
        ? l10n.mosquesSelectGovernorate
        : l10n.mosquesSelectArea;

    if (state.options.isEmpty) {
      return Column(
        children: [
          if (!isGovernorate) _BrowseHeader(state: state),
          Expanded(
            child: EmptyView(
              message: isGovernorate ? l10n.emptyMosques : l10n.emptyAreas,
              icon: Icons.location_off_outlined,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (!isGovernorate) _BrowseHeader(state: state),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
            itemCount: state.options.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextCustom(
                    text: title,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }
              final option = state.options[index - 1];
              return _FacetTile(
                option: option,
                onTap: () {
                  final cubit = context.read<MosqueBrowseCubit>();
                  if (isGovernorate) {
                    cubit.selectGovernorate(option.value);
                  } else {
                    cubit.selectArea(option.value);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One tappable governorate/area row: name, mosque count, chevron.
class _FacetTile extends StatelessWidget {
  final FilterOption option;
  final VoidCallback onTap;
  const _FacetTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 22,
                color: context.colors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextCustom(
                  text: option.value,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (option.count > 0) ...[
                TextCustom(
                  text: '${option.count}',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_right_rounded, color: context.colors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

/// The mosque list — used both for a drilled area and for search results.
class _MosqueResultsList extends StatelessWidget {
  final MosqueBrowseState state;
  final ValueChanged<Mosque> onMosqueTap;
  final Widget Function(Mosque mosque)? trailingBuilder;
  final double bottomPadding;

  const _MosqueResultsList({
    required this.state,
    required this.onMosqueTap,
    required this.trailingBuilder,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showHeader =
        !state.isSearching && state.step == MosqueBrowseStep.mosques;

    if (state.mosques.isEmpty) {
      return Column(
        children: [
          if (showHeader) _BrowseHeader(state: state),
          Expanded(
            child: EmptyView(
              message: state.isSearching
                  ? l10n.noSearchResults
                  : l10n.emptyMosques,
              icon: state.isSearching
                  ? Icons.search_off_rounded
                  : Icons.mosque_outlined,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (showHeader) _BrowseHeader(state: state),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 400) {
                context.read<MosqueBrowseCubit>().loadMore();
              }
              return false;
            },
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.mosques.length + (state.loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= state.mosques.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.colors.primary,
                      ),
                    ),
                  );
                }
                final mosque = state.mosques[index];
                return MosqueCard(
                  mosque: mosque,
                  onTap: () => onMosqueTap(mosque),
                  trailing: trailingBuilder?.call(mosque),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

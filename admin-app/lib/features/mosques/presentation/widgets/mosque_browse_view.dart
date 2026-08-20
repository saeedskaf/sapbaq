import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_form_field.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/mosques/data/mosque_lookup_repository.dart';
import 'package:sapbaq_admin/features/mosques/presentation/bloc/mosque_browse_cubit.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// The one way a mosque is chosen anywhere in this app: search at the top, and
/// below it a governorate → area → mosques drill-down — the same walk, in the
/// same order, as the customer app's picker.
///
/// [pinnedGovernorate] confines the whole browser (drill-down *and* search) to
/// one governorate and drops the governorate level, which is what a regional
/// manager needs: mosques outside his governorate would only 403 at submit.
///
/// Owns its [MosqueBrowseCubit]; a [MosqueLookupRepository] must be available
/// above it.
class MosqueBrowseView extends StatelessWidget {
  final ValueChanged<PickableMosque> onMosqueTap;

  /// Trailing widget per row (e.g. a selected check in an inline picker).
  final Widget Function(PickableMosque mosque)? trailingBuilder;

  final String? pinnedGovernorate;
  final double bottomPadding;

  const MosqueBrowseView({
    super.key,
    required this.onMosqueTap,
    this.trailingBuilder,
    this.pinnedGovernorate,
    this.bottomPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MosqueBrowseCubit(
        context.read<MosqueLookupRepository>(),
        pinnedGovernorate: pinnedGovernorate,
      )..start(),
      child: _MosqueBrowseBody(
        onMosqueTap: onMosqueTap,
        trailingBuilder: trailingBuilder,
        bottomPadding: bottomPadding,
      ),
    );
  }
}

class _MosqueBrowseBody extends StatefulWidget {
  final ValueChanged<PickableMosque> onMosqueTap;
  final Widget Function(PickableMosque mosque)? trailingBuilder;
  final double bottomPadding;

  const _MosqueBrowseBody({
    required this.onMosqueTap,
    required this.trailingBuilder,
    required this.bottomPadding,
  });

  @override
  State<_MosqueBrowseBody> createState() => _MosqueBrowseBodyState();
}

class _MosqueBrowseBodyState extends State<_MosqueBrowseBody> {
  final _searchController = TextEditingController();
  Timer? _debounce;

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
      if (mounted) context.read<MosqueBrowseCubit>().search(query);
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
        Expanded(
          child: BlocBuilder<MosqueBrowseCubit, MosqueBrowseState>(
            builder: (context, state) {
              switch (state.status) {
                case LoadStatus.initial:
                case LoadStatus.loading:
                  return const LoadingView();
                case LoadStatus.failure:
                  return ErrorView(
                    message: state.message ?? l10n.genericError,
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

/// Breadcrumb + back control, shown only where there's a level to go back to.
class _BrowseHeader extends StatelessWidget {
  final MosqueBrowseState state;
  const _BrowseHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    if (!context.read<MosqueBrowseCubit>().canGoBack) {
      return const SizedBox.shrink();
    }
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

/// The governorate / area level: a titled list of facet rows.
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
          _BrowseHeader(state: state),
          Expanded(
            child: EmptyView(
              message: isGovernorate ? l10n.mosquesNone : l10n.mosquesNoAreas,
              icon: Icons.location_off_outlined,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _BrowseHeader(state: state),
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
  final MosqueFacet option;
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

/// The mosque level — also the search results.
class _MosqueResultsList extends StatelessWidget {
  final MosqueBrowseState state;
  final ValueChanged<PickableMosque> onMosqueTap;
  final Widget Function(PickableMosque mosque)? trailingBuilder;
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
                  : l10n.mosquesNone,
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
              separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                return MosqueRowTile(
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

/// One mosque row: name, location line, and an optional trailing widget.
class MosqueRowTile extends StatelessWidget {
  final PickableMosque mosque;
  final VoidCallback onTap;
  final Widget? trailing;

  const MosqueRowTile({
    super.key,
    required this.mosque,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(Icons.mosque_outlined, color: context.colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      text: mosque.name,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (mosque.locationLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      TextCustom(
                        text: mosque.locationLine,
                        fontSize: 12,
                        color: context.colors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

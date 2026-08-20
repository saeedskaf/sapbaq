import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/contribution.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/contributions_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/ops_filter_bar.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/model_thumb.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// The contributions ledger, view-only (amounts/states). Field execution moved
/// to the fulfilment-task queue (unified-dispatch doc §0) — water/equipment
/// settle through their task, maintenance through its case, contracts on
/// payment — so this screen records money, it doesn't act on it.
class ContributionsScreen extends StatelessWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ContributionsCubit(context.read<AdminRepository>())..load(),
      child: const _ContributionsView(),
    );
  }
}

class _ContributionsView extends StatefulWidget {
  const _ContributionsView();

  @override
  State<_ContributionsView> createState() => _ContributionsViewState();
}

class _ContributionsViewState extends State<_ContributionsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      context.read<ContributionsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.ctTitle)),
      body: Column(
        children: [
          const _ContributionsFilterBar(),
          Expanded(
            child: BlocConsumer<ContributionsCubit, ContributionsState>(
              listenWhen: (a, b) => a.message != b.message && b.message != null,
              listener: (context, state) =>
                  ShowMessage.error(context, state.message!),
              builder: (context, state) {
                if (state.status == LoadStatus.loading) {
                  return const LoadingView();
                }
                if (state.status == LoadStatus.failure) {
                  return ErrorView(
                    message: state.message ?? l10n.genericError,
                    retryLabel: l10n.retry,
                    onRetry: () => context.read<ContributionsCubit>().load(),
                  );
                }
                if (state.items.isEmpty) {
                  return EmptyView(
                    message: l10n.opsEmptyQueue,
                    icon: Icons.volunteer_activism_outlined,
                  );
                }
                return RefreshIndicator(
                  color: context.colors.primary,
                  onRefresh: () => context.read<ContributionsCubit>().load(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= state.items.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: context.colors.primary,
                            ),
                          ),
                        );
                      }
                      return _ContributionCard(item: state.items[i]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The month/kind/status filter pills for the contributions queue. Status
/// defaults to `PAID`; `all` returns every status (the server would otherwise
/// default to PAID on an omitted param).
class _ContributionsFilterBar extends StatelessWidget {
  const _ContributionsFilterBar();

  static const _statuses = [
    'all',
    'PENDING',
    'PAID',
    'FULFILLED',
    'EXPIRED',
    'CANCELLED',
  ];
  static const _kinds = ['WATER', 'MAINTENANCE', 'EQUIPMENT'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ContributionsCubit, ContributionsState>(
      buildWhen: (a, b) =>
          a.month != b.month ||
          a.statusFilter != b.statusFilter ||
          a.kindFilter != b.kindFilter,
      builder: (context, state) {
        final cubit = context.read<ContributionsCubit>();
        return OpsFilterBar(
          pills: [
            FilterPill(
              label: state.month.isEmpty
                  ? l10n.opsFilterAllTime
                  : formatMonthKey(context, state.month),
              active: state.month != currentMonthKey(),
              onTap: () async {
                final value = await showFilterOptionsSheet(
                  context,
                  title: l10n.opsFilterMonth,
                  selected: state.month,
                  options: [
                    FilterOption('', l10n.opsFilterAllTime),
                    for (final k in recentMonthKeys())
                      FilterOption(k, formatMonthKey(context, k)),
                  ],
                );
                if (value != null) cubit.setMonth(value);
              },
            ),
            FilterPill(
              label:
                  '${l10n.opsFilterKind}: '
                  '${state.kindFilter.isEmpty ? l10n.opsFilterAny : _kindLabel(l10n, state.kindFilter)}',
              active: state.kindFilter.isNotEmpty,
              onTap: () async {
                final value = await showFilterOptionsSheet(
                  context,
                  title: l10n.opsFilterKind,
                  selected: state.kindFilter,
                  options: [
                    FilterOption('', l10n.opsFilterAny),
                    for (final k in _kinds)
                      FilterOption(k, _kindLabel(l10n, k)),
                  ],
                );
                if (value != null) cubit.setKind(value);
              },
            ),
            FilterPill(
              label:
                  '${l10n.opsFilterStatus}: '
                  '${_ctStatusLabel(l10n, state.statusFilter)}',
              active: state.statusFilter != 'PAID',
              onTap: () async {
                final value = await showFilterOptionsSheet(
                  context,
                  title: l10n.opsFilterStatus,
                  selected: state.statusFilter,
                  options: [
                    for (final s in _statuses)
                      FilterOption(s, _ctStatusLabel(l10n, s)),
                  ],
                );
                if (value != null) cubit.setStatus(value);
              },
            ),
          ],
        );
      },
    );
  }
}

String _ctStatusLabel(AppLocalizations l10n, String status) => switch (status) {
  'all' => l10n.opsFilterAny,
  'PENDING' => l10n.ctStatusPending,
  'PAID' => l10n.ctStatusPaid,
  'FULFILLED' => l10n.ctStatusFulfilled,
  'EXPIRED' => l10n.ctStatusExpired,
  'CANCELLED' => l10n.ctStatusCancelled,
  _ => status,
};

String _kindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'WATER' => l10n.ctKindWater,
  'MAINTENANCE' => l10n.ctKindMaintenance,
  'EQUIPMENT' => l10n.ctKindEquipment,
  _ => kind,
};

IconData _kindIcon(String kind) => switch (kind) {
  'WATER' => Icons.water_drop_rounded,
  'MAINTENANCE' => Icons.build_rounded,
  'EQUIPMENT' => Icons.kitchen_rounded,
  _ => Icons.volunteer_activism_rounded,
};

class _ContributionCard extends StatelessWidget {
  final AdminContribution item;
  const _ContributionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cover = item.modelThumb;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // An equipment contribution funds one specific model — its photo
              // says more than the kind icon it stands in for. The card shows a
              // light thumbnail; tapping opens every angle of that combination.
              if (cover != null)
                ModelThumb(
                  url: cover,
                  size: 44,
                  zoomUrl: item.modelImage ?? cover,
                  zoomUrls: item.modelImages,
                )
              else
                Icon(
                  _kindIcon(item.kind),
                  size: 22,
                  color: context.colors.primary,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: TextCustom(
                  text: _kindLabel(l10n, item.kind),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (item.amount.isNotEmpty)
                TextCustom(
                  text: l10n.priceKwd(item.amount),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.colors.primary,
                ),
            ],
          ),
          if (item.mosque != null && item.mosque!.name.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Meta(icon: Icons.mosque_outlined, text: item.mosque!.name),
          ],
          if (item.detailSummary.isNotEmpty) ...[
            const SizedBox(height: 4),
            _Meta(icon: Icons.info_outline_rounded, text: item.detailSummary),
          ],
          if (item.customer?.fullName.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            _Meta(
              icon: Icons.person_outline,
              text: '${l10n.ctCustomer}: ${item.customer!.fullName}',
            ),
          ],
          const SizedBox(height: 4),
          _Meta(
            icon: Icons.schedule_outlined,
            text: formatDateTimeOf(item.paidAt ?? item.createdAt),
          ),
          // The ledger doesn't act: a paid contribution settles through its
          // fulfilment task (water/equipment) or its maintenance case, so a
          // note says where the work happens instead of offering a button.
          if (item.isPaid) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.autorenew_rounded,
                  size: 16,
                  color: context.colors.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextCustom(
                    text: item.kind == 'MAINTENANCE'
                        ? l10n.ctMaintenanceAutoSettle
                        : l10n.ctViaTasksNote,
                    fontSize: 12.5,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: context.colors.textHint),
        const SizedBox(width: 6),
        Expanded(
          child: TextCustom(
            text: text,
            fontSize: 13,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

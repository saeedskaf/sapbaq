import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/location/location_for_role.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/maintenance_case.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/maintenance_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/direct_provision_fields.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/maintenance_labels.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/ops_filter_bar.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/distance_badge.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Maintenance queue (role-scoped by the server). Each card opens the case
/// detail, where the allowed lifecycle actions live.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MaintenanceCubit(
        context.read<AdminRepository>(),
        location: locationForRole(context),
      )..load(),
      child: const _MaintenanceView(),
    );
  }
}

class _MaintenanceView extends StatefulWidget {
  const _MaintenanceView();

  @override
  State<_MaintenanceView> createState() => _MaintenanceViewState();
}

class _MaintenanceViewState extends State<_MaintenanceView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      context.read<MaintenanceCubit>().loadMore();
    }
  }

  Future<void> _openDetail(MaintenanceCase c) async {
    await context.pushNamed(
      AppRoutes.opsMaintenanceDetailName,
      pathParameters: {'id': '${c.id}'},
    );
    // Actions taken in the detail may change the case; refresh the queue.
    if (mounted) context.read<MaintenanceCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.mtTitle)),
      floatingActionButton: DirectProvisionFab(
        routeName: AppRoutes.opsDirectMaintenanceName,
        tooltip: l10n.dpMaintenance,
        onCreated: () => context.read<MaintenanceCubit>().load(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (q) => context.read<MaintenanceCubit>().setSearch(q),
              decoration: InputDecoration(
                hintText: l10n.mtSearchHint,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.colors.textHint,
                ),
              ),
            ),
          ),
          const _MaintenanceFilterBar(),
          BlocBuilder<MaintenanceCubit, MaintenanceState>(
            buildWhen: (a, b) => a.sortedByDistance != b.sortedByDistance,
            builder: (context, state) =>
                NearestFirstHint(sorted: state.sortedByDistance),
          ),
          Expanded(
            child: BlocBuilder<MaintenanceCubit, MaintenanceState>(
              builder: (context, state) {
                if (state.status == LoadStatus.loading) {
                  return const LoadingView();
                }
                if (state.status == LoadStatus.failure) {
                  return ErrorView(
                    message: state.message ?? l10n.genericError,
                    retryLabel: l10n.retry,
                    onRetry: () => context.read<MaintenanceCubit>().load(),
                  );
                }
                if (state.items.isEmpty) {
                  return EmptyView(
                    message: l10n.opsEmptyQueue,
                    icon: Icons.build_outlined,
                  );
                }
                return RefreshIndicator(
                  color: context.colors.primary,
                  onRefresh: () => context.read<MaintenanceCubit>().load(),
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
                      return _CaseCard(
                        item: state.items[i],
                        sorted: state.sortedByDistance,
                        onTap: () => _openDetail(state.items[i]),
                      );
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

/// The month/status/priority filter pills for the maintenance queue.
class _MaintenanceFilterBar extends StatelessWidget {
  const _MaintenanceFilterBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<MaintenanceCubit, MaintenanceState>(
      buildWhen: (a, b) =>
          a.month != b.month ||
          a.statusFilter != b.statusFilter ||
          a.priorityFilter != b.priorityFilter,
      builder: (context, state) {
        final cubit = context.read<MaintenanceCubit>();
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
                  '${l10n.opsFilterStatus}: '
                  '${state.statusFilter.isEmpty ? l10n.opsFilterAny : mtStatusLabel(l10n, state.statusFilter)}',
              active: state.statusFilter.isNotEmpty,
              onTap: () async {
                final value = await showFilterOptionsSheet(
                  context,
                  title: l10n.opsFilterStatus,
                  selected: state.statusFilter,
                  options: [
                    FilterOption('', l10n.opsFilterAny),
                    for (final s in MaintenanceEnums.statuses)
                      FilterOption(s, mtStatusLabel(l10n, s)),
                  ],
                );
                if (value != null) cubit.setStatus(value);
              },
            ),
            FilterPill(
              label:
                  '${l10n.opsFilterPriority}: '
                  '${state.priorityFilter.isEmpty ? l10n.opsFilterAny : mtPriorityLabel(l10n, state.priorityFilter)}',
              active: state.priorityFilter.isNotEmpty,
              onTap: () async {
                final value = await showFilterOptionsSheet(
                  context,
                  title: l10n.opsFilterPriority,
                  selected: state.priorityFilter,
                  options: [
                    FilterOption('', l10n.opsFilterAny),
                    for (final p in MaintenanceEnums.priorities)
                      FilterOption(p, mtPriorityLabel(l10n, p)),
                  ],
                );
                if (value != null) cubit.setPriority(value);
              },
            ),
          ],
        );
      },
    );
  }
}

class _CaseCard extends StatelessWidget {
  final MaintenanceCase item;
  final VoidCallback onTap;

  /// Whether the queue was sorted nearest-first — gates the distance badge.
  final bool sorted;

  const _CaseCard({
    required this.item,
    required this.onTap,
    this.sorted = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final equip = item.equipment;
    final title = (equip?.equipmentType.isNotEmpty ?? false)
        ? equip!.equipmentType
        : mtIssueLabel(l10n, item.issueType);
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.build_rounded,
                size: 22,
                color: context.colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextCustom(
                  text: title,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // An unassigned approved case is the one a team leader can pull
              // onto his team, so it says so instead of just "approved".
              mtChip(
                item.isClaimable
                    ? l10n.mtReadyToClaim
                    : mtStatusLabel(l10n, item.status),
                mtStatusColor(context, item.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: Icons.report_problem_outlined,
            text: mtIssueLabel(l10n, item.issueType),
          ),
          if (equip != null && equip.mosque.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _MetaRow(
                    icon: Icons.mosque_outlined,
                    text: equip.mosque,
                  ),
                ),
                DistanceBadge(distanceKm: item.distanceKm, sorted: sorted),
                DirectionsButton(mapsUrl: item.mosqueMapsUrl),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (item.priority.isNotEmpty)
                mtChip(
                  mtPriorityLabel(l10n, item.priority),
                  mtPriorityColor(context, item.priority),
                ),
              if (item.isManagerChannel) ...[
                const SizedBox(width: 6),
                mtChip(l10n.mtChannelManager, context.colors.textHint),
              ],
              const Spacer(),
              TextCustom(
                text: formatDateTimeOf(item.createdAt),
                fontSize: 12,
                color: context.colors.textHint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

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

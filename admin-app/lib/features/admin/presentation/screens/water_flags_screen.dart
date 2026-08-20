import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/mosque_need.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/water_flags_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/direct_provision_fields.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/need_card.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/ops_filter_bar.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Water-flags moderation queue (dispatch desk): approve a flag (publishes to
/// donors) or cancel it.
class WaterFlagsScreen extends StatelessWidget {
  const WaterFlagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          WaterFlagsCubit(context.read<AdminRepository>())..load(),
      child: const _WaterFlagsView(),
    );
  }
}

class _WaterFlagsView extends StatefulWidget {
  const _WaterFlagsView();

  @override
  State<_WaterFlagsView> createState() => _WaterFlagsViewState();
}

class _WaterFlagsViewState extends State<_WaterFlagsView> {
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
      context.read<WaterFlagsCubit>().loadMore();
    }
  }

  Future<void> _approve(AdminWaterFlag f) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await context.read<WaterFlagsCubit>().approve(f.id);
    if (ok && mounted) ShowMessage.success(context, l10n.approveSuccess);
  }

  Future<void> _cancel(AdminWaterFlag f) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<WaterFlagsCubit>();
    final confirmed = await showConfirmDialog(
      context,
      message: l10n.opsConfirmCancel,
      confirmLabel: l10n.opsCancelAction,
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    final ok = await cubit.cancel(f.id);
    if (ok && mounted) ShowMessage.success(context, l10n.rejectSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.opsWaterFlags)),
      floatingActionButton: DirectProvisionFab(
        routeName: AppRoutes.opsDirectWaterName,
        tooltip: l10n.dpWater,
        onCreated: () => context.read<WaterFlagsCubit>().load(),
      ),
      body: Column(
        children: [
          const _WaterFlagsFilterBar(),
          Expanded(
            child: BlocConsumer<WaterFlagsCubit, WaterFlagsState>(
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
                    onRetry: () => context.read<WaterFlagsCubit>().load(),
                  );
                }
                if (state.items.isEmpty) {
                  return EmptyView(
                    message: l10n.opsEmptyQueue,
                    icon: Icons.water_drop_outlined,
                  );
                }
                return RefreshIndicator(
                  color: context.colors.primary,
                  onRefresh: () => context.read<WaterFlagsCubit>().load(),
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
                      final f = state.items[i];
                      return NeedCard(
                        icon: Icons.water_drop_rounded,
                        // Singular: the queue's name titles the screen, each
                        // card is one report inside it.
                        title: l10n.opsWaterFlagItem,
                        status: f.status,
                        mosque: f.mosque,
                        details: [
                          NeedDetail(
                            l10n.repFieldDate,
                            formatDateTimeOf(f.createdAt),
                          ),
                        ],
                        busy: state.actioningId == f.id,
                        actions: [
                          if (f.isSubmitted) ...[
                            NeedAction(
                              label: l10n.opsCancelAction,
                              color: ColorsCustom.error,
                              onTap: () => _cancel(f),
                            ),
                            NeedAction.primary(
                              label: l10n.approveButton,
                              onTap: () => _approve(f),
                            ),
                          ],
                        ],
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

/// The status/month filter pills for the water-flags queue.
class _WaterFlagsFilterBar extends StatelessWidget {
  const _WaterFlagsFilterBar();

  static const _statuses = ['SUBMITTED', 'APPROVED', 'FULFILLED', 'CANCELLED'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<WaterFlagsCubit, WaterFlagsState>(
      buildWhen: (a, b) =>
          a.month != b.month || a.statusFilter != b.statusFilter,
      builder: (context, state) {
        final cubit = context.read<WaterFlagsCubit>();
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
                  '${state.statusFilter.isEmpty ? l10n.opsFilterAny : needStatusLabel(l10n, state.statusFilter)}',
              active: state.statusFilter != 'SUBMITTED',
              onTap: () async {
                final value = await showFilterOptionsSheet(
                  context,
                  title: l10n.opsFilterStatus,
                  selected: state.statusFilter,
                  options: [
                    FilterOption('', l10n.opsFilterAny),
                    for (final s in _statuses)
                      FilterOption(s, needStatusLabel(l10n, s)),
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

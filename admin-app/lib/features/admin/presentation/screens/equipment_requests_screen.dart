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
import 'package:sapbaq_admin/features/admin/presentation/bloc/equipment_requests_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/equipment_pick_sheet.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/direct_provision_fields.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/need_card.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/ops_filter_bar.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/core/widgets/reason_sheet.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Equipment-requests moderation queue. Regional managers approve/reject (their
/// governorate, server-scoped); the dispatch desk may only cancel.
class EquipmentRequestsScreen extends StatelessWidget {
  const EquipmentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EquipmentRequestsCubit(context.read<AdminRepository>())..load(),
      child: const _EquipmentRequestsView(),
    );
  }
}

class _EquipmentRequestsView extends StatefulWidget {
  const _EquipmentRequestsView();

  @override
  State<_EquipmentRequestsView> createState() => _EquipmentRequestsViewState();
}

class _EquipmentRequestsViewState extends State<_EquipmentRequestsView> {
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
      context.read<EquipmentRequestsCubit>().loadMore();
    }
  }

  /// Approving is "pick the product and the combination": the choice freezes
  /// the campaign's funding goal, so it can't be a bare confirm.
  Future<void> _approve(AdminEquipmentRequest r) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<EquipmentRequestsCubit>();
    final repo = context.read<AdminRepository>();
    final pick = await showEquipmentPickSheet(
      context,
      load: () => repo.fetchRequestOptions(r.id),
    );
    if (pick == null) return;
    final ok = await cubit.approve(r.id, pick);
    if (ok && mounted) ShowMessage.success(context, l10n.approveSuccess);
  }

  Future<void> _reject(AdminEquipmentRequest r) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<EquipmentRequestsCubit>();
    final reason = await ReasonSheet.show(
      context,
      title: l10n.approvalRejectTitle,
      hint: l10n.approvalRejectHint,
      confirmLabel: l10n.confirmReject,
      danger: true,
    );
    if (reason == null) return;
    final ok = await cubit.reject(r.id, reason);
    if (ok && mounted) ShowMessage.success(context, l10n.rejectSuccess);
  }

  Future<void> _cancel(AdminEquipmentRequest r) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<EquipmentRequestsCubit>();
    final confirmed = await showConfirmDialog(
      context,
      message: l10n.opsConfirmCancel,
      confirmLabel: l10n.opsCancelAction,
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    final ok = await cubit.cancel(r.id);
    if (ok && mounted) ShowMessage.success(context, l10n.rejectSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.read<AuthBloc>().state.user;
    final canApprove = user?.canApproveEquipment ?? false;
    final canCancel = user?.canCancelEquipment ?? false;

    return Scaffold(
      appBar: AppBar(
        title: TextCustom.subheading(text: l10n.opsEquipmentRequests),
      ),
      floatingActionButton: DirectProvisionFab(
        routeName: AppRoutes.opsDirectEquipmentName,
        tooltip: l10n.dpEquipment,
        onCreated: () => context.read<EquipmentRequestsCubit>().load(),
      ),
      body: Column(
        children: [
          const _EquipmentFilterBar(),
          Expanded(
            child: BlocConsumer<EquipmentRequestsCubit, EquipmentRequestsState>(
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
                    onRetry: () =>
                        context.read<EquipmentRequestsCubit>().load(),
                  );
                }
                if (state.items.isEmpty) {
                  return EmptyView(
                    message: l10n.opsEmptyQueue,
                    icon: Icons.kitchen_outlined,
                  );
                }
                return RefreshIndicator(
                  color: context.colors.primary,
                  onRefresh: () =>
                      context.read<EquipmentRequestsCubit>().load(),
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
                      final r = state.items[i];
                      final busy = state.actioningId == r.id;
                      return NeedCard(
                        icon: Icons.kitchen_rounded,
                        title: r.equipmentType.isEmpty
                            ? l10n.opsEquipmentRequestItem
                            : r.equipmentType,
                        status: r.status,
                        mosque: r.mosque,
                        details: [
                          // Set at approval — or already at creation, when a
                          // manager raised the request directly.
                          NeedDetail(l10n.dpModel, r.itemLabel),
                          NeedDetail(l10n.dpTargetAmountLabel, r.targetAmount),
                          NeedDetail(l10n.repFieldNote, r.note),
                          NeedDetail(
                            l10n.repFieldDate,
                            formatDateTimeOf(r.createdAt),
                          ),
                        ],
                        busy: busy,
                        actions: [
                          if (r.isSubmitted && canApprove) ...[
                            NeedAction(
                              label: l10n.rejectButton,
                              color: ColorsCustom.error,
                              onTap: () => _reject(r),
                            ),
                            NeedAction.primary(
                              label: l10n.approveButton,
                              onTap: () => _approve(r),
                            ),
                          ] else if (r.isSubmitted && canCancel)
                            NeedAction(
                              label: l10n.opsCancelAction,
                              color: ColorsCustom.error,
                              onTap: () => _cancel(r),
                            ),
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

/// The status/month filter pills for the equipment-requests queue.
class _EquipmentFilterBar extends StatelessWidget {
  const _EquipmentFilterBar();

  static const _statuses = [
    'SUBMITTED',
    'APPROVED',
    'FULFILLED',
    'REJECTED',
    'CANCELLED',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<EquipmentRequestsCubit, EquipmentRequestsState>(
      buildWhen: (a, b) =>
          a.month != b.month || a.statusFilter != b.statusFilter,
      builder: (context, state) {
        final cubit = context.read<EquipmentRequestsCubit>();
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

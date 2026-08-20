import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/utils/contact_launcher.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/reason_sheet.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/catalog_order.dart';
import 'package:sapbaq_admin/features/admin/data/models/workshop.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/catalog_orders_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/maintenance_labels.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/ops_filter_bar.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/workshop_picker_sheet.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart' show StaffRef;
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// The catalogue-order queue: a customer picked a unit for a mosque, and a
/// manager approves it (opening their 48-hour payment window), then the order
/// walks the usual chain — leader → handler → installed.
///
/// Distinct from the equipment-requests queue, which is the imam asking donors
/// to fund a unit; these two must never be confused, hence the separate screen.
class CatalogOrdersScreen extends StatelessWidget {
  const CatalogOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CatalogOrdersCubit(context.read<AdminRepository>())..load(),
      child: const _CatalogOrdersView(),
    );
  }
}

class _CatalogOrdersView extends StatefulWidget {
  const _CatalogOrdersView();

  @override
  State<_CatalogOrdersView> createState() => _CatalogOrdersViewState();
}

class _CatalogOrdersViewState extends State<_CatalogOrdersView> {
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
      context.read<CatalogOrdersCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.coTitle)),
      body: Column(
        children: [
          const _StatusFilter(),
          Expanded(
            child: BlocConsumer<CatalogOrdersCubit, CatalogOrdersState>(
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
                    onRetry: () => context.read<CatalogOrdersCubit>().load(),
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
                  onRefresh: () => context.read<CatalogOrdersCubit>().load(),
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
                      final order = state.items[i];
                      return _OrderCard(
                        item: order,
                        busy: state.actioningId == order.id,
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

class _StatusFilter extends StatelessWidget {
  const _StatusFilter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CatalogOrdersCubit, CatalogOrdersState>(
      buildWhen: (a, b) => a.statusFilter != b.statusFilter,
      builder: (context, state) {
        final cubit = context.read<CatalogOrdersCubit>();
        return OpsFilterBar(
          pills: [
            FilterPill(
              label:
                  '${l10n.opsFilterStatus}: '
                  '${state.statusFilter.isEmpty ? l10n.opsFilterAny : coStatusLabel(l10n, state.statusFilter)}',
              active: state.statusFilter.isNotEmpty,
              onTap: () async {
                final value = await showFilterOptionsSheet(
                  context,
                  title: l10n.opsFilterStatus,
                  selected: state.statusFilter,
                  options: [
                    FilterOption('', l10n.opsFilterAny),
                    for (final s in CatalogOrderEnums.statuses)
                      FilterOption(s, coStatusLabel(l10n, s)),
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

/// Localized label for a catalogue-order status. The server also sends an
/// Arabic `status_display`, but the staff app is bilingual, so the English
/// enum value is what we translate from.
String coStatusLabel(AppLocalizations l10n, String status) => switch (status) {
  'UNDER_REVIEW' => l10n.coStatusUnderReview,
  'APPROVED' => l10n.coStatusApproved,
  'PAID' => l10n.coStatusPaid,
  'ASSIGNED_TO_TEAM' => l10n.statusAssignedToTeam,
  'ASSIGNED' => l10n.statusAssigned,
  'INSTALLED' => l10n.coStatusInstalled,
  'REJECTED' => l10n.coStatusRejected,
  'CANCELLED' => l10n.statusCancelled,
  _ => status,
};

Color _coStatusColor(BuildContext context, String status) => switch (status) {
  'UNDER_REVIEW' => context.colors.primary,
  'APPROVED' ||
  'PAID' ||
  'ASSIGNED_TO_TEAM' ||
  'ASSIGNED' => ColorsCustom.warning,
  'INSTALLED' => ColorsCustom.success,
  'REJECTED' || 'CANCELLED' => context.colors.danger,
  _ => context.colors.textHint,
};

class _OrderCard extends StatelessWidget {
  final CatalogOrder item;
  final bool busy;
  const _OrderCard({required this.item, required this.busy});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The name is the headline and runs long once the variant is appended
          // ("مبرّد مياه ستيل — حوضان — عادي"), so it gets the full card width
          // and wraps; the status pill drops to its own line rather than
          // squeezing the name into a truncated sliver.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.kitchen_rounded,
                size: 22,
                color: context.colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextCustom(
                  text: item.modelName.isEmpty ? item.code : item.modelName,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          mtChip(
            coStatusLabel(l10n, item.status),
            _coStatusColor(context, item.status),
          ),
          const SizedBox(height: 10),
          if (item.mosque != null)
            _Meta(
              icon: Icons.mosque_outlined,
              text: [
                item.mosque!.name,
                item.mosque!.locationLine,
              ].where((s) => s.isNotEmpty).join(' — '),
            ),
          _Meta(icon: Icons.confirmation_number_outlined, text: item.code),
          // The customer is reachable straight from the row: an approver often
          // needs to ask about the mosque choice before deciding.
          if (item.customer != null) _CustomerLine(customer: item.customer!),
          if (item.dedicationName.isNotEmpty)
            _Meta(
              icon: Icons.card_giftcard_outlined,
              text: item.dedicationName,
            ),
          if (item.teamLeader != null)
            _Meta(
              icon: Icons.supervisor_account_outlined,
              text: '${l10n.mtFieldTeamLeader}: ${item.teamLeader!.fullName}',
            ),
          if (item.assignedTo != null)
            _Meta(
              icon: Icons.engineering_outlined,
              text: '${l10n.ftFieldHandler}: ${item.assignedTo!.fullName}',
            ),
          if (item.installedCode.isNotEmpty)
            _Meta(icon: Icons.qr_code_2_rounded, text: item.installedCode),
          if (item.rejectionReason.isNotEmpty)
            _Meta(
              icon: Icons.block_rounded,
              text: item.rejectionReason,
              color: context.colors.danger,
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextCustom(
                text: l10n.priceKwd(item.unitPrice),
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: context.colors.primary,
              ),
              const Spacer(),
              TextCustom(
                text: formatDateTimeOf(item.createdAt),
                fontSize: 12,
                color: context.colors.textHint,
              ),
            ],
          ),
          // While the window is open the customer may still not pay, so say so
          // rather than leaving the queue looking stalled.
          if (item.status == 'APPROVED' && item.payDeadline != null) ...[
            const SizedBox(height: 8),
            mtChip(
              l10n.coAwaitingPayment(formatDateTimeOf(item.payDeadline)),
              ColorsCustom.warning,
            ),
          ],
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _Actions(item: item),
        ],
      ),
    );
  }
}

/// The role- and status-gated buttons, decided by the pure
/// [visibleCatalogOrderActions] matrix; the server stays authoritative.
class _Actions extends StatelessWidget {
  final CatalogOrder item;
  const _Actions({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.read<AuthBloc>().state.user;
    final actions = visibleCatalogOrderActions(
      status: item.status,
      isManager: user?.canProvisionDirect ?? false,
      isAssignedLeader: user != null && item.teamLeader?.id == user.id,
      isAssignedHandler: user != null && item.assignedTo?.id == user.id,
    );
    if (actions.isEmpty) return const SizedBox.shrink();

    final handler = _ActionHandler(context, item);
    final buttons = <Widget>[
      if (actions.contains(CatalogOrderAction.approve))
        ButtonCustom.primary(
          text: l10n.approveButton,
          onPressed: handler.approve,
        ),
      if (actions.contains(CatalogOrderAction.assignLeader))
        ButtonCustom.primary(
          text: l10n.mtAssignLeader,
          onPressed: handler.assignLeader,
        ),
      if (actions.contains(CatalogOrderAction.assignHandler))
        ButtonCustom.primary(
          text: l10n.ftAssignHandler,
          onPressed: handler.assignHandler,
        ),
      if (actions.contains(CatalogOrderAction.install))
        ButtonCustom.primary(text: l10n.coInstall, onPressed: handler.install),
      if (actions.contains(CatalogOrderAction.reject))
        ButtonCustom.secondary(
          text: l10n.rejectButton,
          onPressed: handler.reject,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            buttons[i],
          ],
        ],
      ),
    );
  }
}

/// Wires each action to its picker/prompt and reports the outcome.
class _ActionHandler {
  final BuildContext context;
  final CatalogOrder item;
  _ActionHandler(this.context, this.item);

  CatalogOrdersCubit get _cubit => context.read<CatalogOrdersCubit>();
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  void _done(bool ok) {
    if (ok && context.mounted) ShowMessage.success(context, _l10n.mtActionDone);
  }

  Future<void> approve() async {
    // Approving starts the customer's 48-hour clock, so it's confirmed rather
    // than fired on a single tap.
    final ok = await showConfirmDialog(
      context,
      message: _l10n.coApproveConfirm,
      confirmLabel: _l10n.approveButton,
    );
    if (ok == true) _done(await _cubit.approve(item.id));
  }

  Future<void> reject() async {
    final reason = await ReasonSheet.show(
      context,
      title: _l10n.approvalRejectTitle,
      hint: _l10n.approvalRejectHint,
      confirmLabel: _l10n.rejectButton,
    );
    if (reason != null && reason.isNotEmpty) {
      _done(await _cubit.reject(item.id, reason));
    }
  }

  Future<void> assignLeader() async {
    final list = await _load(
      () => context.read<AdminRepository>().fetchCatalogTeamLeaders(item.id),
    );
    if (list == null) return;
    if (list.isEmpty) {
      if (context.mounted) ShowMessage.info(context, _l10n.mtNoLeaders);
      return;
    }
    final id = await _pickStaff(_l10n.mtChooseLeader, list);
    if (id != null) _done(await _cubit.assignLeader(item.id, id));
  }

  Future<void> assignHandler() async {
    final list = await _load(
      () => context.read<AdminRepository>().fetchCatalogHandlers(item.id),
    );
    if (list == null) return;
    if (list.isEmpty) {
      if (context.mounted) ShowMessage.info(context, _l10n.mtNoMembers);
      return;
    }
    final id = await _pickStaff(_l10n.ftChooseHandler, list);
    if (id != null) _done(await _cubit.assignHandler(item.id, id));
  }

  Future<void> install() async {
    // Installing mints a real unit with a warranty — not something to undo.
    final ok = await showConfirmDialog(
      context,
      message: _l10n.coInstallConfirm,
      confirmLabel: _l10n.coInstall,
    );
    if (ok == true) _done(await _cubit.install(item.id));
  }

  /// Runs a picker load behind a blocking spinner; null means it failed (the
  /// message was already shown).
  Future<List<Workshop>?> _load(Future<List<Workshop>> Function() run) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      // `canPop: false` matters as much as `barrierDismissible`: without it an
      // Android back gesture closes the spinner, and the pop below then takes
      // the screen underneath with it.
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    try {
      return await run();
    } on ApiException catch (e) {
      if (context.mounted) ShowMessage.error(context, e.message);
      return null;
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<int?> _pickStaff(String title, List<Workshop> staff) {
    return showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) =>
          WorkshopPickerSheet(workshops: staff, title: title),
    ).then((value) => value);
  }
}

/// The ordering customer with call / WhatsApp shortcuts.
class _CustomerLine extends StatelessWidget {
  final StaffRef customer;
  const _CustomerLine({required this.customer});

  Future<void> _call(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await dialPhone(customer.phone);
    if (!ok && context.mounted) ShowMessage.info(context, l10n.contactFailed);
  }

  Future<void> _whatsapp(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await openWhatsApp(customer.phone);
    if (!ok && context.mounted) ShowMessage.info(context, l10n.contactFailed);
  }

  @override
  Widget build(BuildContext context) {
    final name = customer.fullName.isEmpty ? customer.phone : customer.fullName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 15,
            color: context.colors.textHint,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextCustom(
              text: name,
              fontSize: 13,
              color: context.colors.textSecondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (customer.phone.isNotEmpty) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context)!.callButton,
              icon: Icon(
                Icons.call_rounded,
                size: 18,
                color: context.colors.primary,
              ),
              onPressed: () => _call(context),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context)!.whatsappButton,
              icon: Icon(
                Icons.chat_rounded,
                size: 18,
                color: context.colors.primary,
              ),
              onPressed: () => _whatsapp(context),
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
  final Color? color;
  const _Meta({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color ?? context.colors.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: TextCustom(
              text: text,
              fontSize: 13,
              color: color ?? context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

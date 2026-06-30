import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/utils/contact_launcher.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/utils/maps_launcher.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/reason_sheet.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
import 'package:sapbaq_admin/features/admin/data/models/workshop.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/admin_order_detail_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/mosque_picker_sheet.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/workshop_picker_sheet.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/shared/presentation/order_sections.dart';
import 'package:sapbaq_admin/features/shared/presentation/status_badge.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

class AdminOrderDetailScreen extends StatelessWidget {
  final int orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AdminOrderDetailCubit(context.read<AdminRepository>(), orderId)
            ..load(),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<AdminOrderDetailCubit>();
    final l10n = AppLocalizations.of(context)!;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: ColorsCustom.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CancelSheet(),
    );
    if (reason == null) return;
    final ok = await cubit.cancel(reason);
    if (ok && context.mounted) ShowMessage.success(context, l10n.orderCancelled);
  }

  /// Manager flow (T3): assign the whole order to a team leader, who then
  /// distributes each destination to a handler.
  Future<void> _assignTeam(BuildContext context) async {
    final cubit = context.read<AdminOrderDetailCubit>();
    final l10n = AppLocalizations.of(context)!;
    final leaders = await cubit.fetchTeamLeaders();
    if (leaders == null || !context.mounted) return; // error already surfaced
    if (leaders.isEmpty) {
      ShowMessage.info(context, l10n.noTeamLeaders);
      return;
    }
    final chosen = await _pickStaff(context, leaders, l10n.chooseTeamLeader);
    if (chosen == null || !context.mounted) return;
    final ok = await cubit.assignTeam(chosen.id);
    if (ok && context.mounted) ShowMessage.success(context, l10n.assignTeamSuccess);
  }

  /// Team-leader flow (T3): distribute one destination to a handler.
  Future<void> _distribute(BuildContext context, AdminDestination d) async {
    final cubit = context.read<AdminOrderDetailCubit>();
    final l10n = AppLocalizations.of(context)!;
    final picked = await _pickHandler(context, d, l10n.chooseWorkshop);
    if (picked == null || !context.mounted) return;
    final ok = await cubit.assignHandler(
      d.id,
      picked.driverId,
      mosqueId: picked.mosqueId,
    );
    if (ok && context.mounted) ShowMessage.success(context, l10n.distributeSuccess);
  }

  /// Team-leader flow (T3): approve a destination's completion directly,
  /// recording the handler who carried it out.
  Future<void> _complete(BuildContext context, AdminDestination d) async {
    final cubit = context.read<AdminOrderDetailCubit>();
    final l10n = AppLocalizations.of(context)!;
    final picked = await _pickHandler(context, d, l10n.chooseHandlerWhoDelivered);
    if (picked == null || !context.mounted) return;
    final ok = await cubit.completeDestination(
      d.id,
      picked.driverId,
      mosqueId: picked.mosqueId,
    );
    if (ok && context.mounted) ShowMessage.success(context, l10n.completeSuccess);
  }

  /// Pick a handler (and a mosque first, for an unlocated MOST_NEEDED
  /// destination). Returns null if the user aborts at any step.
  Future<({int driverId, int? mosqueId})?> _pickHandler(
    BuildContext context,
    AdminDestination d,
    String title,
  ) async {
    final cubit = context.read<AdminOrderDetailCubit>();
    int? mosqueId;
    if (d.needsMosque) {
      final mosque = await _pickMosque(context);
      if (mosque == null || !context.mounted) return null;
      mosqueId = mosque.id;
    }
    final workshops = await cubit.fetchWorkshops();
    if (workshops == null || !context.mounted) return null;
    final l10n = AppLocalizations.of(context)!;
    if (workshops.isEmpty) {
      ShowMessage.info(context, l10n.noWorkshops);
      return null;
    }
    final chosen = await _pickStaff(context, workshops, title);
    if (chosen == null) return null;
    return (driverId: chosen.id, mosqueId: mosqueId);
  }

  Future<Workshop?> _pickStaff(
    BuildContext context,
    List<Workshop> staff,
    String title,
  ) {
    return showModalBottomSheet<Workshop>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: ColorsCustom.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WorkshopPickerSheet(workshops: staff, title: title),
    );
  }

  Future<({int id, String name})?> _pickMosque(BuildContext context) {
    return showModalBottomSheet<({int id, String name})>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: ColorsCustom.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MosquePickerSheet(
        repository: context.read<AdminRepository>(),
      ),
    );
  }

  /// Move one already-assigned destination to a different workshop (§5).
  Future<void> _openReassign(BuildContext context, AdminDestination d) async {
    final cubit = context.read<AdminOrderDetailCubit>();
    final l10n = AppLocalizations.of(context)!;
    final workshops = await cubit.fetchWorkshops();
    if (workshops == null || !context.mounted) return; // error already surfaced
    // The backend rejects a no-op to the current workshop, so drop it.
    final options = workshops.where((w) => w.id != d.driver?.id).toList();
    if (options.isEmpty) {
      ShowMessage.info(context, l10n.noOtherWorkshops);
      return;
    }
    final chosen = await showModalBottomSheet<Workshop>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: ColorsCustom.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WorkshopPickerSheet(workshops: options),
    );
    if (chosen == null || !context.mounted) return;
    final ok = await cubit.reassign(d.id, chosen.id);
    if (ok && context.mounted) {
      ShowMessage.success(context, l10n.reassignSuccess);
    }
  }

  Future<void> _call(BuildContext context, String phone) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await dialPhone(phone);
    if (!ok && context.mounted) ShowMessage.info(context, l10n.contactFailed);
  }

  Future<void> _whatsapp(BuildContext context, String phone) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await openWhatsApp(phone);
    if (!ok && context.mounted) ShowMessage.info(context, l10n.contactFailed);
  }

  Future<void> _raiseEscalation(BuildContext context) async {
    final cubit = context.read<AdminOrderDetailCubit>();
    final l10n = AppLocalizations.of(context)!;
    final reason = await ReasonSheet.show(
      context,
      title: l10n.raiseEscalationTitle,
      hint: l10n.raiseEscalationHint,
      confirmLabel: l10n.raiseEscalationTitle,
    );
    if (reason == null || reason.isEmpty) return;
    final ok = await cubit.raiseEscalation(reason);
    if (ok && context.mounted) {
      ShowMessage.success(context, l10n.escalationRaised);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AdminOrderDetailCubit, AdminOrderDetailState>(
      listenWhen: (a, b) => a.message != b.message && b.message != null,
      listener: (context, state) => ShowMessage.error(context, state.message!),
      builder: (context, state) {
        final order = state.order;
        final user = context.read<AuthBloc>().state.user;
        return Scaffold(
          appBar: AppBar(
            title: TextCustom.subheading(
              text: order == null
                  ? l10n.orderDetailsTitle
                  : l10n.orderRefShort(order.shortReference),
            ),
            actions: [
              if (order != null)
                IconButton(
                  tooltip: l10n.raiseEscalationTitle,
                  icon: const Icon(Icons.campaign_outlined),
                  onPressed: () => _raiseEscalation(context),
                ),
            ],
          ),
          body: _body(context, state, l10n),
          bottomNavigationBar: order == null
              ? null
              : _ActionBar(
                  order: order,
                  cancelling: state.cancelling,
                  canAssign: user?.canAssignOrders ?? false,
                  canCancel: user?.canCancelOrders ?? false,
                  onAssign: () => _assignTeam(context),
                  onCancel: () => _confirmCancel(context),
                ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AdminOrderDetailState state,
    AppLocalizations l10n,
  ) {
    if (state.status == LoadStatus.loading && state.order == null) {
      return const LoadingView();
    }
    if (state.status == LoadStatus.failure && state.order == null) {
      return ErrorView(
        message: state.message ?? l10n.genericError,
        retryLabel: l10n.retry,
        onRetry: () => context.read<AdminOrderDetailCubit>().load(),
      );
    }
    final order = state.order;
    if (order == null) return const SizedBox.shrink();

    final user = context.read<AuthBloc>().state.user;
    final canReassign = user?.canReassignOrders ?? false;
    final canDispatch = user?.canDispatchTeam ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            StatusBadge(status: order.status),
            const Spacer(),
            if (order.hasGift)
              Row(
                children: [
                  const Icon(
                    Icons.card_giftcard_rounded,
                    size: 16,
                    color: ColorsCustom.secondary,
                  ),
                  const SizedBox(width: 4),
                  TextCustom.caption(text: l10n.giftLabel),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (order.customer != null)
          SectionCard(
            title: l10n.customerLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: order.customer!.fullName,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 4),
                TextCustom(
                  text: order.customer!.phone,
                  fontSize: 13,
                  color: ColorsCustom.textSecondary,
                ),
                if (order.customer!.phone.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.call_rounded,
                          label: l10n.callButton,
                          color: ColorsCustom.primary,
                          onTap: () => _call(context, order.customer!.phone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ContactButton(
                          icon: Icons.chat_rounded,
                          label: l10n.whatsappButton,
                          color: ColorsCustom.success,
                          onTap: () =>
                              _whatsapp(context, order.customer!.phone),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        if (order.payment != null)
          SectionCard(
            title: l10n.paymentLabel,
            child: Row(
              children: [
                Icon(
                  order.payment!.isPaid
                      ? Icons.check_circle_rounded
                      : Icons.pending_rounded,
                  size: 18,
                  color: order.payment!.isPaid
                      ? ColorsCustom.success
                      : ColorsCustom.warning,
                ),
                const SizedBox(width: 8),
                TextCustom(
                  text: order.payment!.isPaid ? l10n.paymentPaid : l10n.paymentUnpaid,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: order.payment!.isPaid
                      ? ColorsCustom.success
                      : ColorsCustom.warning,
                ),
                const Spacer(),
                TextCustom(
                  text: l10n.priceKwd(order.payment!.amount),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ],
            ),
          ),
        if ((order.customerNotes ?? '').isNotEmpty)
          SectionCard(
            title: l10n.notesLabel,
            child: TextCustom(
              text: order.customerNotes!,
              fontSize: 14,
              color: ColorsCustom.textSecondary,
            ),
          ),
        const SizedBox(height: 4),
        TextCustom.subheading(text: l10n.destinationsLabel, fontSize: 16),
        const SizedBox(height: 8),
        ...order.destinations.map(
          (d) => DestinationSection(
            label: d.label,
            destinationType: d.destinationType,
            status: d.status,
            mosque: d.mosque,
            items: d.items,
            subtotal: d.subtotal,
            driverName: d.driver?.fullName,
            teamLeaderName: d.teamLeader?.fullName,
            showTimeline: true,
            assignedAt: d.assignedAt,
            inDeliveryAt: d.inDeliveryAt,
            deliveredAt: d.deliveredAt,
            cancelledAt: d.cancelledAt,
            onOpenLocation: () => _openLocation(context, d, l10n),
            onReassign: (canReassign && d.isReassignable)
                ? () => _openReassign(context, d)
                : null,
            onDistribute: (canDispatch && d.isAssignedToTeam)
                ? () => _distribute(context, d)
                : null,
            onComplete: (canDispatch && d.isAssignedToTeam)
                ? () => _complete(context, d)
                : null,
          ),
        ),
        if (order.cancellationReason != null &&
            order.cancellationReason!.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionCard(
            title: l10n.cancelReasonLabel,
            child: TextCustom(
              text: order.cancellationReason!,
              fontSize: 14,
              color: ColorsCustom.error,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _TotalRow(label: l10n.totalLabel, amount: order.totalAmount, l10n: l10n),
        if (order.timeline.isNotEmpty) ...[
          const SizedBox(height: 16),
          _TimelineSection(events: order.timeline),
        ],
      ],
    );
  }

  Future<void> _openLocation(
    BuildContext context,
    AdminDestination d,
    AppLocalizations l10n,
  ) async {
    final opened = await openMapsUrl(d.mosque?.mapsUrl);
    if (!opened && context.mounted) {
      final address = d.mosque?.address ?? '';
      ShowMessage.info(
        context,
        address.isEmpty ? l10n.noLocation : address,
      );
    }
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String amount;
  final AppLocalizations l10n;
  const _TotalRow({
    required this.label,
    required this.amount,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ColorsCustom.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          TextCustom(text: label, fontSize: 15, fontWeight: FontWeight.w700),
          const Spacer(),
          TextCustom(
            text: l10n.priceKwd(amount),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ColorsCustom.primary,
          ),
        ],
      ),
    );
  }
}

/// A compact tinted action button used for customer contact (call / WhatsApp).
class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              TextCustom(
                text: label,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The order's event history (§4), rendered as a vertical timeline. Events
/// arrive oldest→newest; [OrderTimelineEvent.label] is server-localized.
class _TimelineSection extends StatelessWidget {
  final List<OrderTimelineEvent> events;
  const _TimelineSection({required this.events});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SectionCard(
      title: l10n.timelineLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < events.length; i++)
            _TimelineRow(event: events[i], isLast: i == events.length - 1),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final OrderTimelineEvent event;
  final bool isLast;
  const _TimelineRow({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final time = formatShortDateTime(event.at);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: isLast ? ColorsCustom.primary : ColorsCustom.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: ColorsCustom.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom(
                    text: event.label,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    TextCustom(
                      text: time,
                      fontSize: 12,
                      color: ColorsCustom.textHint,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final AdminOrderDetail order;
  final bool cancelling;
  final bool canAssign;
  final bool canCancel;
  final VoidCallback onAssign;
  final VoidCallback onCancel;

  const _ActionBar({
    required this.order,
    required this.cancelling,
    required this.canAssign,
    required this.canCancel,
    required this.onAssign,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Show an action only when the order allows it AND the role may perform it
    // (permission is a UI hint; the server is authoritative — see User §13).
    final showAssign = order.awaitingAssignment && canAssign;
    final showCancel = order.isCancellable && canCancel;
    if (!showAssign && !showCancel) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAssign)
            ButtonCustom.primary(
              text: l10n.assignToTeamLeaderButton,
              icon: const Icon(
                Icons.groups_outlined,
                color: ColorsCustom.textOnPrimary,
                size: 20,
              ),
              onPressed: onAssign,
            ),
          if (showAssign && showCancel) const SizedBox(height: 10),
          if (showCancel)
            ButtonCustom(
              text: l10n.cancelOrderButton,
              color: ColorsCustom.error,
              textColor: ColorsCustom.textOnPrimary,
              isLoading: cancelling,
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet collecting a cancellation reason; pops the reason string.
class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorsCustom.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextCustom.subheading(text: l10n.cancelOrderTitle, color: ColorsCustom.error),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.cancelReasonHint),
          ),
          const SizedBox(height: 20),
          ButtonCustom(
            text: l10n.confirmCancel,
            color: ColorsCustom.error,
            textColor: ColorsCustom.textOnPrimary,
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          ),
          const SizedBox(height: 10),
          ButtonCustom.secondary(
            text: l10n.keepOrder,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

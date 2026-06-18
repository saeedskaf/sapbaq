import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/utils/maps_launcher.dart';
import 'package:sapbaq_admin/core/widgets/custom_button.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/admin_order_detail_cubit.dart';
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

  Future<void> _openAssign(BuildContext context, int orderId) async {
    await context.pushNamed(
      AppRoutes.adminAssignName,
      pathParameters: {'id': '$orderId'},
    );
    // Reload to reflect any assignment made on the pushed screen.
    if (context.mounted) context.read<AdminOrderDetailCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AdminOrderDetailCubit, AdminOrderDetailState>(
      listenWhen: (a, b) => a.message != b.message && b.message != null,
      listener: (context, state) => ShowMessage.error(context, state.message!),
      builder: (context, state) {
        final order = state.order;
        return Scaffold(
          appBar: AppBar(
            title: TextCustom.subheading(
              text: order == null
                  ? l10n.orderDetailsTitle
                  : l10n.orderRefShort(order.shortReference),
            ),
          ),
          body: _body(context, state, l10n),
          bottomNavigationBar: order == null
              ? null
              : _ActionBar(
                  order: order,
                  cancelling: state.cancelling,
                  onAssign: () => _openAssign(context, order.id),
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
            onOpenLocation: () => _openLocation(context, d, l10n),
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

class _ActionBar extends StatelessWidget {
  final AdminOrderDetail order;
  final bool cancelling;
  final VoidCallback onAssign;
  final VoidCallback onCancel;

  const _ActionBar({
    required this.order,
    required this.cancelling,
    required this.onAssign,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!order.awaitingAssignment && !order.isCancellable) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (order.awaitingAssignment)
            ButtonCustom.primary(
              text: l10n.assignButton,
              icon: const Icon(
                Icons.assignment_ind_outlined,
                color: ColorsCustom.textOnPrimary,
                size: 20,
              ),
              onPressed: onAssign,
            ),
          if (order.awaitingAssignment && order.isCancellable)
            const SizedBox(height: 10),
          if (order.isCancellable)
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

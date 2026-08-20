import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/payments/payment_gateway.dart';
import 'package:sapbaq/core/payments/payment_sheet.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/date_format.dart';
import 'package:sapbaq/core/widgets/confirm_sheet.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/product_thumb.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/equipment/data/equipment_repository.dart';
import 'package:sapbaq/features/equipment/data/models/equipment_models.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// «طلبات المعدّات» as its own screen — what a push deep-link and the
/// post-submit hand-off open. The same [EquipmentRequestsView] also lives as the
/// «معدّات» tab of «طلباتي», so the two can never drift apart.
class EquipmentRequestsScreen extends StatelessWidget {
  /// Opens this request's detail sheet once the list has loaded.
  final int? focusRequestId;

  const EquipmentRequestsScreen({super.key, this.focusRequestId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: TextCustom.subheading(text: l10n.equipMyRequestsTitle),
      ),
      // A pushed screen sits above the shell, so there's no floating nav bar to
      // clear here.
      body: EquipmentRequestsView(
        focusRequestId: focusRequestId,
        underFloatingNav: false,
      ),
    );
  }
}

/// The customer's catalogue requests and where each one is: under review,
/// approved with a payment window ticking, being installed, or done
/// (FLUTTER_NONLIVE_EQUIPMENT_ORDERING §3). Bodyless — no Scaffold — so it can
/// be either a screen or a tab.
class EquipmentRequestsView extends StatefulWidget {
  /// From `equip_order.*` pushes: the request to surface as soon as the list
  /// arrives. An approval push opens the 48-hour window, so it must land on the
  /// pay button, not just near it.
  final int? focusRequestId;

  /// True inside the «طلباتي» shell tab, where the list must clear the floating
  /// nav bar; false on the pushed standalone screen, which has none.
  final bool underFloatingNav;

  const EquipmentRequestsView({
    super.key,
    this.focusRequestId,
    this.underFloatingNav = true,
  });

  @override
  State<EquipmentRequestsView> createState() => _EquipmentRequestsViewState();
}

class _EquipmentRequestsViewState extends State<EquipmentRequestsView>
    with AutomaticKeepAliveClientMixin {
  LoadStatus _status = LoadStatus.loading;
  List<EquipmentRequest> _requests = const [];
  String? _error;
  int? _busyId;

  /// Tabs keep their loaded list when the user switches away and back.
  @override
  bool get wantKeepAlive => true;

  /// One-shot: a focused request opens its sheet on the first load only, never
  /// again on a pull-to-refresh.
  bool _focusHandled = false;

  /// Drives the payment-window countdowns. One timer for the screen, not one
  /// per row, and it only runs while something is actually counting down.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    final counting = _requests.any((r) => r.canPay);
    if (counting) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {});
        // A window that just lapsed leaves nothing to count down; stop rather
        // than rebuild the screen every second for the rest of the session.
        _syncTicker();
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final requests = await context.read<EquipmentRepository>().myRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _status = LoadStatus.success;
      });
      _syncTicker();
      await _openFocused();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = LoadStatus.failure;
        _error = e.message;
      });
    }
  }

  /// Surface the deep-linked request as a detail sheet over the list. The row
  /// is normally already in hand; a request the list didn't carry is fetched by
  /// id rather than silently ignored.
  Future<void> _openFocused() async {
    final id = widget.focusRequestId;
    if (id == null || _focusHandled || !mounted) return;
    _focusHandled = true;

    var request = _requests.where((r) => r.id == id).firstOrNull;
    if (request == null) {
      try {
        request = await context.read<EquipmentRepository>().fetchRequest(id);
      } on ApiException {
        // Not ours, or gone — the list itself is still worth showing.
        return;
      }
    }
    if (!mounted) return;
    final action = await showEquipmentRequestSheet(context, request);
    if (!mounted || action == null) return;
    switch (action) {
      case EquipmentRequestAction.pay:
        await _pay(request);
      case EquipmentRequestAction.cancel:
        await _cancel(request);
    }
  }

  Future<void> _pay(EquipmentRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busyId = request.id);
    final gateway = PaymentGateway(context.read<PaymentRepository>());
    final repo = context.read<EquipmentRepository>();
    final result = await gateway.run(
      context,
      initiate: () => context
          .read<PaymentRepository>()
          .initiateEquipmentPayment(request.id),
      target: PaymentTarget.equipmentRequest(request.id),
      // A failed `confirm` proves nothing — the server settles payments on its
      // own. Ask the request itself instead of reading the error.
      verifyPaid: () async =>
          (await repo.fetchRequest(request.id)).status !=
          EquipmentRequestStatus.approved,
    );
    if (!mounted) return;
    setState(() => _busyId = null);

    if (result.isDismissed) {
      // Closed the sheet on purpose. The request keeps its payment window and
      // its «ادفع الآن» button; saying anything here would only be noise.
    } else if (result.isPaid) {
      ShowMessage.success(context, l10n.paidThanks);
    } else if (result.isPending) {
      // The gateway hasn't decided yet — don't call it a failure, the charge
      // may still land (backend answers §3).
      ShowMessage.info(context, l10n.payPendingBody);
    } else if (result.code == 'pay_window_closed') {
      // The 48-hour window after approval has run out, and the request is gone
      // with it. That is the one failure with an obvious next move — the unit is
      // still in the catalogue and can simply be asked for again — so offer it
      // rather than leaving a dead row and a red message the customer has to
      // work out for themselves.
      final again = await ConfirmSheet.ask(
        context,
        title: l10n.equipWindowClosed,
        body: result.message,
        icon: Icons.timer_off_rounded,
        danger: false,
        confirmLabel: l10n.equipRequestAction,
        cancelLabel: l10n.closeButton,
        invertEmphasis: true,
      );
      if (again && mounted) {
        context.pushNamed(AppRoutes.equipmentRequestFormName);
      }
    } else {
      // The server's own message wins when it sent one (a lapsed window, say);
      // otherwise say whether the gateway refused the card or we simply
      // couldn't settle — those call for different actions.
      ShowMessage.error(
        context,
        result.message ??
            (result.isDeclined ? l10n.payDeclinedBody : l10n.payFailedBody),
      );
    }
    // Reload either way: paid moves the row on, and a lapsed window flips it to
    // cancelled server-side.
    await _load();
  }

  Future<void> _cancel(EquipmentRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmSheet.ask(
      context,
      title: l10n.equipCancelConfirm,
      body: l10n.equipCancelBody,
      icon: Icons.remove_shopping_cart_outlined,
      confirmLabel: l10n.equipCancelRequest,
      cancelLabel: l10n.keepOrder,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyId = request.id);
    try {
      await context.read<EquipmentRepository>().cancelRequest(request.id);
      if (mounted) ShowMessage.success(context, l10n.equipCancelled);
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return switch (_status) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(),
      LoadStatus.failure => ErrorView(
        message: _error ?? l10n.comingSoon,
        retryLabel: l10n.retry,
        onRetry: _load,
      ),
      LoadStatus.success =>
        _requests.isEmpty
            ? EmptyView(
                message: l10n.equipNoRequests,
                icon: Icons.kitchen_outlined,
              )
            : RefreshIndicator(
                color: context.colors.primary,
                onRefresh: _load,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    widget.underFloatingNav
                        ? floatingNavBarClearance(context)
                        : 28,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _RequestCard(
                    request: _requests[i],
                    busy: _busyId == _requests[i].id,
                    onPay: () => _pay(_requests[i]),
                    onCancel: () => _cancel(_requests[i]),
                  ),
                ),
              ),
    };
  }
}

/// What the detail sheet resolves to when the customer acts from it.
enum EquipmentRequestAction { pay, cancel }

/// One request in full, over whatever list opened it — the same card the list
/// renders, so a deep-linked approval shows its countdown and pay button
/// without a second layout to keep in sync.
Future<EquipmentRequestAction?> showEquipmentRequestSheet(
  BuildContext context,
  EquipmentRequest request,
) {
  return showModalBottomSheet<EquipmentRequestAction>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: sheetContext.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: sheetContext.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _RequestCard(
                request: request,
                busy: false,
                onPay: () =>
                    Navigator.pop(sheetContext, EquipmentRequestAction.pay),
                onCancel: () =>
                    Navigator.pop(sheetContext, EquipmentRequestAction.cancel),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RequestCard extends StatelessWidget {
  final EquipmentRequest request;
  final bool busy;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  const _RequestCard({
    required this.request,
    required this.busy,
    required this.onPay,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = _statusLabel(context, l10n, request);
    // The picked variant's photo wins; the base product's is the fallback.
    final variantImage = request.variant?.image ?? '';
    final image = variantImage.isNotEmpty
        ? variantImage
        : (request.product?.image ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProductThumb(
                url: image.isEmpty ? null : image,
                size: 44,
                placeholderIcon: Icons.kitchen_rounded,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextCustom(
                  text: request.itemLabel.isEmpty
                      ? request.code
                      : request.itemLabel,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _Chip(label: label, color: color),
            ],
          ),
          const SizedBox(height: 8),
          if (request.mosque != null)
            _Line(icon: Icons.mosque_outlined, text: request.mosque!.name),
          _Line(icon: Icons.confirmation_number_outlined, text: request.code),
          _Line(
            icon: Icons.event_outlined,
            text: formatShortDateTime(request.createdAt?.toIso8601String()),
          ),
          if (request.dedicationName.isNotEmpty)
            _Line(
              icon: Icons.card_giftcard_outlined,
              text: request.dedicationName,
            ),
          if (request.installedCode.isNotEmpty)
            _Line(
              icon: Icons.qr_code_2_rounded,
              text: '${l10n.equipInstalledCode}: ${request.installedCode}',
            ),
          if (request.status == EquipmentRequestStatus.rejected &&
              request.rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextCustom(
                text:
                    '${l10n.equipRejectionReason}: ${request.rejectionReason}',
                fontSize: 12.5,
                color: context.colors.danger,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              TextCustom(
                text: l10n.priceKwd(request.unitPrice),
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: context.colors.primary,
              ),
              const Spacer(),
              if (request.canPay) _Countdown(request: request),
            ],
          ),
          if (request.windowClosed) ...[
            const SizedBox(height: 6),
            TextCustom(
              text: l10n.equipWindowClosed,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colors.danger,
            ),
          ],
          if (busy) ...[
            const SizedBox(height: 14),
            Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            ),
          ] else if (request.canPay || request.canCancel) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (request.canCancel)
                  Expanded(
                    child: ButtonCustom.secondary(
                      text: l10n.equipCancelRequest,
                      height: 44,
                      onPressed: onCancel,
                    ),
                  ),
                if (request.canPay && request.canCancel)
                  const SizedBox(width: 10),
                if (request.canPay)
                  Expanded(
                    child: ButtonCustom.primary(
                      text: l10n.payNow,
                      height: 44,
                      onPressed: onPay,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// `ASSIGNED_TO_TEAM`/`ASSIGNED` are dispatch bookkeeping — the customer just
  /// needs "being installed".
  (String, Color) _statusLabel(
    BuildContext context,
    AppLocalizations l10n,
    EquipmentRequest r,
  ) => switch (r.status) {
    EquipmentRequestStatus.underReview => (
      l10n.equipStatusUnderReview,
      context.colors.primary,
    ),
    EquipmentRequestStatus.approved => (
      l10n.equipStatusApproved,
      ColorsCustom.warning,
    ),
    EquipmentRequestStatus.paid => (l10n.equipStatusPaid, ColorsCustom.success),
    EquipmentRequestStatus.assignedToTeam || EquipmentRequestStatus.assigned =>
      (l10n.equipStatusInProgress, ColorsCustom.warning),
    EquipmentRequestStatus.installed => (
      l10n.equipStatusInstalled,
      ColorsCustom.success,
    ),
    EquipmentRequestStatus.rejected => (
      l10n.equipStatusRejected,
      ColorsCustom.error,
    ),
    EquipmentRequestStatus.cancelled => (
      l10n.equipStatusCancelled,
      ColorsCustom.error,
    ),
    EquipmentRequestStatus.unknown => ('—', context.colors.textHint),
  };
}

/// Time left in the 48-hour window, recomputed from `pay_deadline` on each
/// rebuild — never counted down locally, so backgrounding the app can't leave
/// a stale number on screen.
class _Countdown extends StatelessWidget {
  final EquipmentRequest request;
  const _Countdown({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final left = request.timeLeftToPay ?? Duration.zero;
    // Under three hours the backend is already sending "final notice" pushes —
    // match that urgency here.
    final urgent = left.inHours < 3;
    final hours = left.inHours;
    final minutes = left.inMinutes % 60;
    final seconds = left.inSeconds % 60;
    final text = hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}'
              ':${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}'
              ':${seconds.toString().padLeft(2, '0')}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          size: 15,
          color: urgent ? context.colors.danger : context.colors.textSecondary,
        ),
        const SizedBox(width: 4),
        TextCustom(
          text: l10n.equipPayWindow(text),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: urgent ? context.colors.danger : context.colors.textSecondary,
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Line({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: context.colors.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: TextCustom(
              text: text,
              fontSize: 12.5,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextCustom(
      text: label,
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: color,
    ),
  );
}

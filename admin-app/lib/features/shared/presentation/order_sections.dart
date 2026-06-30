import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/features/shared/data/models/mosque.dart';
import 'package:sapbaq_admin/features/shared/data/models/order_item.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/pill.dart';
import 'package:sapbaq_admin/features/shared/presentation/status_badge.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// A small, muted section label used above grouped content.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextCustom(
      text: text,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: ColorsCustom.textHint,
    );
  }
}

/// A titled, borderless card — the standard grouping container on the
/// order/destination detail screens.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// A destination card shared by the admin order detail and the driver
/// destination detail: the destination name + type + status, the mosque (with
/// an "open location" action), the items, and the subtotal. [driverName] shows
/// the assigned workshop (admin view); [teamLeaderName] shows the team leader
/// the order was assigned to. Omit [onOpenLocation] to hide the location
/// action. Pass [onReassign] (admin view) to move an assigned destination to
/// another workshop, or [onDistribute] / [onComplete] (team-leader view) to
/// hand a team-assigned destination to a handler or approve it directly.
/// When [showTimeline] is set, a per-destination status timeline (T4) renders
/// from [status] and the lifecycle timestamps.
class DestinationSection extends StatelessWidget {
  final String label;
  final String destinationType;
  final String status;
  final Mosque? mosque;
  final List<OrderItem> items;
  final String subtotal;
  final String? driverName;
  final String? teamLeaderName;
  final VoidCallback? onOpenLocation;
  final VoidCallback? onReassign;
  final VoidCallback? onDistribute;
  final VoidCallback? onComplete;
  final bool showTimeline;
  final String? assignedAt;
  final String? inDeliveryAt;
  final String? deliveredAt;
  final String? cancelledAt;

  const DestinationSection({
    super.key,
    required this.label,
    required this.destinationType,
    required this.status,
    required this.items,
    required this.subtotal,
    this.mosque,
    this.driverName,
    this.teamLeaderName,
    this.onOpenLocation,
    this.onReassign,
    this.onDistribute,
    this.onComplete,
    this.showTimeline = false,
    this.assignedAt,
    this.inDeliveryAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = mosque == null
        ? ''
        : [mosque!.area, mosque!.address].where((s) => s.isNotEmpty).join(' — ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      text: label,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    TextCustom(
                      text: destinationTypeLabel(l10n, destinationType),
                      fontSize: 12.5,
                      color: ColorsCustom.textHint,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: status),
            ],
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MetaLine(icon: Icons.place_outlined, text: location),
          ],
          if (teamLeaderName != null && teamLeaderName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MetaLine(
              icon: Icons.groups_outlined,
              text: '${l10n.teamLeaderLabel}: $teamLeaderName',
            ),
          ],
          if (driverName != null && driverName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MetaLine(
              icon: Icons.engineering_outlined,
              text: '${l10n.assignedWorkshopLabel}: $driverName',
            ),
          ],
          if (showTimeline) ...[
            const SizedBox(height: 14),
            DestinationStatusTimeline(
              status: status,
              assignedAt: assignedAt,
              inDeliveryAt: inDeliveryAt,
              deliveredAt: deliveredAt,
              cancelledAt: cancelledAt,
            ),
          ],
          if (onOpenLocation != null ||
              onReassign != null ||
              onDistribute != null ||
              onComplete != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: [
                if (onOpenLocation != null)
                  _DestinationAction(
                    icon: Icons.map_outlined,
                    label: l10n.openLocation,
                    color: ColorsCustom.primary,
                    onPressed: onOpenLocation!,
                  ),
                if (onDistribute != null)
                  _DestinationAction(
                    icon: Icons.engineering_outlined,
                    label: l10n.distributeToHandler,
                    color: ColorsCustom.primary,
                    onPressed: onDistribute!,
                  ),
                if (onComplete != null)
                  _DestinationAction(
                    icon: Icons.task_alt_rounded,
                    label: l10n.approveCompletion,
                    color: ColorsCustom.success,
                    onPressed: onComplete!,
                  ),
                if (onReassign != null)
                  _DestinationAction(
                    icon: Icons.swap_horiz_rounded,
                    label: l10n.reassignButton,
                    color: ColorsCustom.secondary,
                    onPressed: onReassign!,
                  ),
              ],
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...items.map((item) => _ItemRow(item: item, l10n: l10n)),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              TextCustom(
                text: l10n.subtotalLabel,
                fontSize: 13,
                color: ColorsCustom.textSecondary,
              ),
              const Spacer(),
              TextCustom(
                text: l10n.priceKwd(subtotal),
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: ColorsCustom.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact text button used for the per-destination actions row.
class _DestinationAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _DestinationAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 18, color: color),
      label: TextCustom(
        text: label,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

/// Per-destination status timeline (FLUTTER_TASKS T4). Each destination is
/// delivered independently, so progress is driven by `destination.status` +
/// its lifecycle timestamps — not the coarse `order.status`. Reached steps are
/// highlighted with their timestamp; upcoming steps are muted. A cancelled
/// destination shows a single cancelled row instead.
class DestinationStatusTimeline extends StatelessWidget {
  final String status;
  final String? assignedAt;
  final String? inDeliveryAt;
  final String? deliveredAt;
  final String? cancelledAt;

  const DestinationStatusTimeline({
    super.key,
    required this.status,
    this.assignedAt,
    this.inDeliveryAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  static const List<String> _steps = [
    'PENDING',
    'ASSIGNED_TO_TEAM',
    'ASSIGNED',
    'IN_DELIVERY',
    'DELIVERED',
  ];

  String? _timeFor(String step) {
    switch (step) {
      case 'ASSIGNED':
        return assignedAt;
      case 'IN_DELIVERY':
        return inDeliveryAt;
      case 'DELIVERED':
        return deliveredAt;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (status == 'CANCELLED') {
      return _TimelineStep(
        label: statusLabel(l10n, 'CANCELLED'),
        time: formatShortDateTime(cancelledAt),
        done: true,
        isLast: true,
        color: ColorsCustom.error,
      );
    }

    final current = _steps.indexOf(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++)
          _TimelineStep(
            label: statusLabel(l10n, _steps[i]),
            time: formatShortDateTime(_timeFor(_steps[i])),
            done: current >= 0 && i <= current,
            isLast: i == _steps.length - 1,
            color: ColorsCustom.primary,
          ),
      ],
    );
  }
}

/// One row of [DestinationStatusTimeline]: a dot + connector and the step's
/// label/time, dimmed when the step hasn't been reached yet.
class _TimelineStep extends StatelessWidget {
  final String label;
  final String time;
  final bool done;
  final bool isLast;
  final Color color;
  const _TimelineStep({
    required this.label,
    required this.time,
    required this.done,
    required this.isLast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = done ? color : ColorsCustom.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: ColorsCustom.border)),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextCustom(
                      text: label,
                      fontSize: 13,
                      fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                      color: done
                          ? ColorsCustom.textPrimary
                          : ColorsCustom.textHint,
                    ),
                  ),
                  if (done && time.isNotEmpty)
                    TextCustom(
                      text: time,
                      fontSize: 11.5,
                      color: ColorsCustom.textHint,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A muted icon + text line (location, assigned workshop, …).
class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: ColorsCustom.textHint),
        const SizedBox(width: 6),
        Expanded(
          child: TextCustom(
            text: text,
            fontSize: 13,
            color: ColorsCustom.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  final AppLocalizations l10n;
  const _ItemRow({required this.item, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Pill(
            text: '×${item.quantity}',
            color: ColorsCustom.primary,
            background: ColorsCustom.surfaceVariant,
            fontSize: 12,
            radius: 8,
            hPad: 8,
            vPad: 4,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextCustom(
              text: item.product.name,
              fontSize: 14,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextCustom(
            text: l10n.priceKwd(item.lineTotal),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ColorsCustom.textSecondary,
          ),
        ],
      ),
    );
  }
}

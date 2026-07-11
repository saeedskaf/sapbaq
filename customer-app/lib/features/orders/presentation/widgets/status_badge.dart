import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

String orderStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    // ASSIGNED_TO_TEAM is an internal staff hand-off the customer shouldn't see;
    // surface it as "pending" until a handler is actually assigned.
    case 'PENDING':
    case 'ASSIGNED_TO_TEAM':
      return l10n.statusPending;
    case 'CONFIRMED':
      return l10n.statusConfirmed;
    case 'ASSIGNED':
      return l10n.statusAssigned;
    case 'IN_DELIVERY':
      return l10n.statusInDelivery;
    case 'DELIVERED':
      return l10n.statusDelivered;
    case 'CANCELLED':
      return l10n.statusCancelled;
    default:
      return status;
  }
}

Color orderStatusColor(BuildContext context, String status) {
  switch (status) {
    case 'PENDING':
    case 'ASSIGNED_TO_TEAM':
      return ColorsCustom.warning;
    case 'CONFIRMED':
    case 'ASSIGNED':
    case 'IN_DELIVERY':
      return context.colors.primary;
    case 'DELIVERED':
      return ColorsCustom.success;
    case 'CANCELLED':
      return ColorsCustom.error;
    default:
      return context.colors.textHint;
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = orderStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextCustom(
        text: orderStatusLabel(l10n, status),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/features/shared/presentation/pill.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Arabic label for an order/destination status. The same status vocabulary is
/// shared across orders (PENDING/CONFIRMED/DELIVERED/CANCELLED) and destinations
/// (PENDING/ASSIGNED/IN_DELIVERY/DELIVERED/CANCELLED).
String statusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'PENDING':
      return l10n.statusPending;
    case 'CONFIRMED':
      return l10n.statusConfirmed;
    case 'ASSIGNED_TO_TEAM':
      return l10n.statusAssignedToTeam;
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

Color statusColor(String status) {
  switch (status) {
    case 'PENDING':
      return ColorsCustom.warning;
    case 'CONFIRMED':
      return ColorsCustom.info;
    case 'ASSIGNED_TO_TEAM':
      return ColorsCustom.secondary;
    case 'ASSIGNED':
      return ColorsCustom.primaryLight;
    case 'IN_DELIVERY':
      return ColorsCustom.primary;
    case 'DELIVERED':
      return ColorsCustom.success;
    case 'CANCELLED':
      return ColorsCustom.error;
    default:
      return ColorsCustom.textHint;
  }
}

/// Arabic label for a destination type (MOSQUE / MOST_NEEDED).
String destinationTypeLabel(AppLocalizations l10n, String type) {
  return type == 'MOST_NEEDED' ? l10n.typeMostNeeded : l10n.typeMosque;
}

/// A small pill rendering a status with its color (tinted background).
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Pill(text: statusLabel(l10n, status), color: statusColor(status));
  }
}

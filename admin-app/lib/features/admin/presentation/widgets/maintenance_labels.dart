import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Localized labels + colours for the maintenance enums (admin returns raw
/// values only; the app translates them).

String mtStatusLabel(AppLocalizations l10n, String status) => switch (status) {
  'SUBMITTED' => l10n.mtStatusSubmitted,
  'ACKNOWLEDGED' => l10n.mtStatusAcknowledged,
  'APPROVED' => l10n.mtStatusApproved,
  'ASSIGNED' => l10n.mtStatusAssigned,
  'IN_PROGRESS' => l10n.mtStatusInProgress,
  'COMPLETED' => l10n.mtStatusCompleted,
  'RESOLVED' => l10n.mtStatusResolved,
  'DUPLICATE' => l10n.mtStatusDuplicate,
  'CANCELLED' => l10n.mtStatusCancelled,
  _ => status,
};

Color mtStatusColor(BuildContext context, String status) => switch (status) {
  'SUBMITTED' || 'ACKNOWLEDGED' => context.colors.primary,
  'APPROVED' ||
  'ASSIGNED' ||
  'IN_PROGRESS' ||
  'COMPLETED' => ColorsCustom.warning,
  'RESOLVED' => ColorsCustom.success,
  'CANCELLED' => context.colors.danger,
  _ => context.colors.textHint,
};

String mtPriorityLabel(AppLocalizations l10n, String p) => switch (p) {
  'LOW' => l10n.mtPriorityLow,
  'MEDIUM' => l10n.mtPriorityMedium,
  'HIGH' => l10n.mtPriorityHigh,
  'URGENT' => l10n.mtPriorityUrgent,
  _ => p,
};

Color mtPriorityColor(BuildContext context, String p) => switch (p) {
  'LOW' => context.colors.textHint,
  'MEDIUM' => context.colors.primary,
  'HIGH' => ColorsCustom.warning,
  'URGENT' => context.colors.danger,
  _ => context.colors.textHint,
};

String mtCostLabel(AppLocalizations l10n, String c) => switch (c) {
  'FREE_WARRANTY' => l10n.mtCostFreeWarranty,
  'MANUFACTURER_COMPRESSOR' => l10n.mtCostManufacturer,
  'CUSTOMER_PAID' => l10n.mtCostCustomerPaid,
  _ => l10n.mtCostUnset,
};

String mtIssueLabel(AppLocalizations l10n, String issue) => switch (issue) {
  'FILTER_CHANGE' => l10n.repIssueFilterChange,
  'NOT_WORKING' => l10n.repIssueNotWorking,
  'LEAKING' => l10n.repIssueLeaking,
  'OTHER' => l10n.repIssueOther,
  _ => issue,
};

/// A small filled pill for a status/priority label.
Widget mtChip(String label, Color color) => Container(
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

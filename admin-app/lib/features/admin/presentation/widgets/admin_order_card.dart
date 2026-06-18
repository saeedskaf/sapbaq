import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/utils/date_format.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/pill.dart';
import 'package:sapbaq_admin/features/shared/presentation/status_badge.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// A tappable card summarizing one order in the admin list: the customer +
/// status on top, a `#ref · destinations` meta line, then a hairline footer
/// with the total and the awaiting cue (or date).
class AdminOrderCard extends StatelessWidget {
  final AdminOrderSummary order;
  final VoidCallback onTap;

  const AdminOrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customer = order.customer;
    final displayName = customer == null || customer.fullName.isEmpty
        ? (customer?.phone ?? l10n.customerLabel)
        : customer.fullName;

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextCustom(
                  text: displayName,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                size: 13,
                color: ColorsCustom.textHint,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: TextCustom(
                  text: '#${order.shortReference}',
                  fontSize: 12.5,
                  color: ColorsCustom.textSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextCustom(
                text: '  ·  ${l10n.destinationsCount(order.destinationCount)}',
                fontSize: 12.5,
                color: ColorsCustom.textHint,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: ColorsCustom.border),
          ),
          Row(
            children: [
              TextCustom(
                text: l10n.priceKwd(order.totalAmount),
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: ColorsCustom.primary,
              ),
              const Spacer(),
              if (order.awaitingAssignment)
                Pill(
                  text: l10n.awaitingAssignmentBadge,
                  color: ColorsCustom.warning,
                  fontSize: 11,
                )
              else if (order.createdAt != null)
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: ColorsCustom.textHint,
                    ),
                    const SizedBox(width: 4),
                    TextCustom(
                      text: formatShortDate(order.createdAt),
                      fontSize: 12,
                      color: ColorsCustom.textHint,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

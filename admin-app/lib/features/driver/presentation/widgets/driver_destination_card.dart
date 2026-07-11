import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/features/driver/data/models/driver_destination.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/status_badge.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// A tappable card summarizing one assigned destination in the driver list.
class DriverDestinationCard extends StatelessWidget {
  final DriverDestination destination;
  final VoidCallback onTap;

  const DriverDestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final area = destination.mosque?.area ?? '';
    final meta = [
      l10n.orderRefShort(destination.displayCode),
      if (area.isNotEmpty) area,
    ].join(' · ');

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextCustom(
                  text: destination.label,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(status: destination.status),
            ],
          ),
          const SizedBox(height: 8),
          TextCustom(
            text: meta,
            fontSize: 13,
            color: context.colors.textSecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if ((destination.customerNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 15,
                  color: context.colors.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextCustom(
                    text: destination.customerNotes!,
                    fontSize: 12.5,
                    color: context.colors.textHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

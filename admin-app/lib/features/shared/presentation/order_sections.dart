import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
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
/// the assigned workshop (admin view); omit [onOpenLocation] to hide the
/// location action.
class DestinationSection extends StatelessWidget {
  final String label;
  final String destinationType;
  final String status;
  final Mosque? mosque;
  final List<OrderItem> items;
  final String subtotal;
  final String? driverName;
  final VoidCallback? onOpenLocation;

  const DestinationSection({
    super.key,
    required this.label,
    required this.destinationType,
    required this.status,
    required this.items,
    required this.subtotal,
    this.mosque,
    this.driverName,
    this.onOpenLocation,
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
          if (driverName != null && driverName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MetaLine(
              icon: Icons.engineering_outlined,
              text: '${l10n.assignedWorkshopLabel}: $driverName',
            ),
          ],
          if (onOpenLocation != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onOpenLocation,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: TextCustom(
                  text: l10n.openLocation,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColorsCustom.primary,
                ),
              ),
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

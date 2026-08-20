import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';

/// One entry on an operations hub: an icon chip, the queue's name, a line
/// saying what the queue holds and what *this* role does with it, and — for
/// queues — a status line carrying the pending count.
///
/// The explanation and the status line are the point. The hub used to be a
/// stack of identical rows with a bare number, which told a staff member
/// neither what a queue was nor whether a numberless row meant "clear" or
/// "nothing counted for you"; both questions are now answered on the card.
class OpsEntryCard extends StatelessWidget {
  final IconData icon;
  final String title;

  /// What this queue is and what the signed-in role does with it.
  final String description;

  /// The line under [description]. Null on entries that aren't queues (the
  /// direct-request actions), which carry no waiting state.
  final String? status;

  /// True when [status] reports work waiting: it renders as a tinted chip
  /// instead of muted text, so a card that needs attention is spotted while
  /// scrolling past the ones that don't.
  final bool statusActive;

  final VoidCallback onTap;

  const OpsEntryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.status,
    this.statusActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colors.textSecondary, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextCustom(
                  text: title,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textHint,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextCustom(
            text: description,
            fontSize: 12.5,
            color: colors.textSecondary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (status != null) ...[
            const SizedBox(height: 12),
            _StatusLine(label: status!, active: statusActive),
          ],
        ],
      ),
    );
  }
}

/// "3 items need your action" as a tinted chip, or the quiet "nothing new"
/// state as plain hint text.
class _StatusLine extends StatelessWidget {
  final String label;
  final bool active;
  const _StatusLine({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (!active) {
      return TextCustom(
        text: label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.textHint,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: ColorsCustom.brandMint,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: ColorsCustom.onMint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: TextCustom(
              text: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colors.primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

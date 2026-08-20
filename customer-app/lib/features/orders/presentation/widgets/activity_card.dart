import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/date_format.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/most_needed_badge.dart';
import 'package:sapbaq/core/widgets/product_thumb.dart';
import 'package:sapbaq/features/orders/data/models/activity.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// One row of «طلباتي», whatever kind it is. With no tabs to separate them, the
/// card itself must say what it is, where it goes, where it stands, and what —
/// if anything — the donor still has to do.
///
/// Every string comes from the server already composed and translated; nothing
/// here builds a label (delivery §5.1).
class ActivityCard extends StatelessWidget {
  final ActivityRow row;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  const ActivityCard({super.key, required this.row, this.onTap, this.onAction});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final action = row.action;
    final showAction = action != null && action.isPay && onAction != null;
    // The pay window belongs to the card, not to the button: the button reads
    // identically on every card and the clock keeps one fixed place above it.
    final left = action != null && action.isPay ? action.timeLeft : null;
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          // No padding here: the action bar runs edge to edge, so the inset
          // belongs to the content row alone. The frame is a *foreground*
          // decoration — a background one paints before the children, so the
          // action bar would cover the bottom edge and leave the border open.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              // What still needs the donor gets a visible edge; the attached
              // bar below carries the rest of the signal.
              color: row.needsAction
                  ? context.colors.primary
                  : context.colors.border,
              width: row.needsAction ? 1 : 0.6,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Block 1 — what it is and where it goes.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProductThumb(
                          url: row.image,
                          size: 56,
                          radius: 12,
                          placeholderIcon: switch (row.kind) {
                            ActivityKind.equipmentRequest =>
                              Icons.kitchen_outlined,
                            ActivityKind.contribution =>
                              Icons.volunteer_activism_outlined,
                            _ => Icons.shopping_bag_outlined,
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Body(row: row, l10n: l10n),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Block 2 — the receipt line, spanning the whole card
                    // rather than the narrow column beside the thumbnail: the
                    // reference and date at the start, the amount at the end.
                    // The amount used to share the title's line, where a long
                    // title squeezed it and a wrapping one left it stranded.
                    _Footer(row: row, l10n: l10n),
                  ],
                ),
              ),
              // Block 3 — what is still owed, and the one thing to press.
              if (showAction)
                _ActionBar(l10n: l10n, left: left, onTap: onAction!),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final ActivityRow row;
  final AppLocalizations l10n;

  const _Body({required this.row, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final mosque = row.mosque;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Status leads — it is what the donor scans for; the kind is the
            // quiet label the removed tabs used to carry.
            Flexible(child: _StatusChip(row: row)),
            const SizedBox(width: 6),
            _KindChip(kind: row.kind, l10n: l10n),
          ],
        ),
        const SizedBox(height: 6),
        // Full width now that the amount moved down to the receipt line, so a
        // long product name gets two honest lines instead of one and a half.
        TextCustom(
          text: row.title,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (row.subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          TextCustom(
            text: row.subtitle,
            fontSize: 13,
            color: context.colors.textSecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (mosque != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              // Marks this line as the destination — without it a mosque name
              // reads like just another grey subtitle.
              Icon(
                Icons.mosque_outlined,
                size: 14,
                color: context.colors.textHint,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: TextCustom(
                  text: mosque.name,
                  fontSize: 13,
                  color: context.colors.textSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (mosque.isMostNeeded) ...[
                const SizedBox(width: 6),
                const MostNeededBadge(),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// The card's receipt line: reference and date at the start, amount at the end.
///
/// Both halves are Latin-script runs inside Arabic copy, so this is where the
/// direction handling has to be right — the reference and date are joined into
/// one string and rendered as a single left-to-right run (digits keep their
/// order), while the line as a whole hugs the layout's start edge.
class _Footer extends StatelessWidget {
  final ActivityRow row;
  final AppLocalizations l10n;

  const _Footer({required this.row, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final created = row.createdAt;
    final meta = [
      if (row.reference.isNotEmpty) row.reference,
      if (created != null) formatShortDate(created.toIso8601String()),
    ].join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextCustom(
            text: meta,
            fontSize: 12.5,
            color: context.colors.textHint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        TextCustom(
          text: l10n.priceKwd(row.amount),
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
          color: context.colors.textPrimary,
        ),
      ],
    );
  }
}

/// The remaining pay window — its own line above the button, never beside it,
/// so the button's width never depends on whether the server sent a deadline.
/// Recomputed from that deadline on each rebuild rather than ticked locally, so
/// backgrounding the app can't leave a stale number on screen.
class _PayCountdown extends StatelessWidget {
  final Duration left;
  final AppLocalizations l10n;

  const _PayCountdown({required this.left, required this.l10n});

  @override
  Widget build(BuildContext context) {
    // Under three hours the backend is already sending "final notice" pushes —
    // match that urgency here, same threshold as the equipment requests list.
    final color = left.inHours < 3
        ? context.colors.danger
        : ColorsCustom.warning;
    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 15, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: TextCustom(
            text: l10n.payWindowLeft(_format(left)),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// "47:22" for hours, "12:40" for minutes — enough precision to feel like a
  /// clock without pretending to tick every second.
  static String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}'
        : '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// The kind badge — what the removed tabs used to say.
class _KindChip extends StatelessWidget {
  final ActivityKind kind;
  final AppLocalizations l10n;

  const _KindChip({required this.kind, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final label = switch (kind) {
      ActivityKind.productOrder => l10n.activityKindProducts,
      ActivityKind.equipmentRequest => l10n.activityKindEquipment,
      ActivityKind.contribution => l10n.activityKindContribution,
      ActivityKind.unknown => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();
    // Deliberately neutral: two filled chips side by side read as noise, and
    // between "what it is" and "where it stands", the status is what the
    // donor is scanning for.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextCustom(
        text: label,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: context.colors.textSecondary,
      ),
    );
  }
}

/// The status, coloured by its group alone — the app never learns the thirty
/// statuses behind it.
class _StatusChip extends StatelessWidget {
  final ActivityRow row;
  const _StatusChip({required this.row});

  @override
  Widget build(BuildContext context) {
    if (row.statusLabel.isEmpty) return const SizedBox.shrink();
    // Signals are solid with the label onSignal picks; in-progress is the
    // ordinary case and stays a quiet grey chip.
    final (bg, fg) = switch (row.statusGroup) {
      ActivityStatusGroup.actionRequired => (
        ColorsCustom.warning,
        ColorsCustom.onSignal(ColorsCustom.warning),
      ),
      ActivityStatusGroup.done => (
        ColorsCustom.success,
        ColorsCustom.onSignal(ColorsCustom.success),
      ),
      ActivityStatusGroup.cancelled => (
        ColorsCustom.error,
        ColorsCustom.onSignal(ColorsCustom.error),
      ),
      ActivityStatusGroup.inProgress => (
        context.colors.surfaceVariant,
        context.colors.textSecondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextCustom(
        text: row.statusLabel,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: fg,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// The attached call-to-action strip along the card's bottom edge: the
/// countdown on its own line (when the server sent a deadline — the equipment
/// window, a contribution hold) above a full-width pay button. The two used to
/// share one row, which left the button a different width on every card.
class _ActionBar extends StatelessWidget {
  final AppLocalizations l10n;
  final Duration? left;
  final VoidCallback onTap;

  const _ActionBar({
    required this.l10n,
    required this.left,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = left;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A hairline is all the separation the strip needs — no fill behind
        // the button.
        Divider(height: 1, thickness: 1, color: context.colors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (remaining != null) ...[
                _PayCountdown(left: remaining, l10n: l10n),
                const SizedBox(height: 8),
              ],
              _PayButton(l10n: l10n, onTap: onTap),
            ],
          ),
        ),
      ],
    );
  }
}

/// Solid brand button inside the action strip — the one thing on the card the
/// donor is meant to press.
class _PayButton extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _PayButton({required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Brand-fixed deep green with white on top in both themes — the same pair
    // the floating cart bar uses. (The theme's `onPrimary` is the near-black
    // meant for mint fills; on this deep green it read as dark-on-dark.)
    const background = ColorsCustom.primary;
    const foreground = ColorsCustom.textOnPrimary;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.payments_rounded, size: 18, color: foreground),
              const SizedBox(width: 7),
              TextCustom(
                text: l10n.payNow,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Surface card wrapper shared by the three marketplace tabs.
class MarketplaceCard extends StatelessWidget {
  final Widget child;
  const MarketplaceCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border, width: 0.6),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

/// How far an equipment campaign has got: the paid-only progress bar, the
/// funded/target line, and what is still open to fund. Shared by the campaign
/// card and the contribution sheet so both always read the same.
///
/// `reserved_amount` is deliberately absent — a donor reads "reserved" as
/// "already funded"; its effect is already inside the remaining figure.
class FundingProgress extends StatelessWidget {
  final EquipmentFunding funding;
  const FundingProgress({super.key, required this.funding});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: funding.ratio,
            minHeight: 8,
            backgroundColor: context.colors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(context.colors.primary),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextCustom(
                text: l10n.fundedOfTarget(
                  funding.fundedAmount,
                  funding.targetAmount,
                ),
                fontSize: 12,
                color: context.colors.textSecondary,
              ),
            ),
            TextCustom(
              text: l10n.fundingRemaining(funding.remaining),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ],
        ),
      ],
    );
  }
}

/// Mosque header row: a tinted icon chip, the mosque name, and a one-line
/// subtitle (area/governorate or address, per the feed).
class MosqueLine extends StatelessWidget {
  final MosqueRef mosque;
  final IconData icon;
  final String? subtitle;
  const MosqueLine({
    super.key,
    required this.mosque,
    this.icon = Icons.mosque_rounded,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtitle ?? mosque.areaLine;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: context.colors.textSecondary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextCustom(
                text: mosque.name,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                TextCustom(
                  text: sub,
                  fontSize: 12.5,
                  color: context.colors.textSecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

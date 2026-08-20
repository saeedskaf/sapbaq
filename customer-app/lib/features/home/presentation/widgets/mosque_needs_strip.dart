import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/marketplace/data/marketplace_repository.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Compact Mosque-Needs marketplace entry on the storefront: title + live
/// per-tab counts (from `GET /marketplace/summary/`). Counts are decoration —
/// the strip renders (and navigates) fine without them.
class MosqueNeedsStrip extends StatefulWidget {
  const MosqueNeedsStrip({super.key});

  @override
  State<MosqueNeedsStrip> createState() => MosqueNeedsStripState();
}

class MosqueNeedsStripState extends State<MosqueNeedsStrip> {
  MarketplaceSummary? _summary;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  /// Re-fetches the live counts — called by the storefront's pull-to-refresh.
  Future<void> reload() => _fetch();

  Future<void> _fetch() async {
    try {
      final summary = await context.read<MarketplaceRepository>().summary();
      if (mounted) setState(() => _summary = summary);
    } catch (_) {
      // Non-critical decoration — the strip works without counts.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _summary;
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(AppRoutes.marketplaceName),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.border, width: 0.6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.mosque_rounded,
                    color: context.colors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextCustom(
                        text: l10n.mosqueNeedsTitle,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      TextCustom(
                        text: l10n.mosqueNeedsDesc,
                        fontSize: 12,
                        color: context.colors.textSecondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (summary != null && summary.total > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _CountPill(
                              icon: Icons.water_drop_rounded,
                              count: summary.water,
                            ),
                            const SizedBox(width: 6),
                            _CountPill(
                              icon: Icons.build_rounded,
                              count: summary.maintenance,
                            ),
                            const SizedBox(width: 6),
                            _CountPill(
                              icon: Icons.kitchen_rounded,
                              count: summary.equipment,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  // arrow_forward auto-mirrors under RTL
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: context.colors.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final IconData icon;
  final int count;
  const _CountPill({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.colors.textSecondary),
          const SizedBox(width: 3),
          TextCustom(
            text: '$count',
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: context.colors.primary,
          ),
        ],
      ),
    );
  }
}

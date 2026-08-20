import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/ops_entry_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// The regional/global manager's "direct request" entry (manager-direct doc §1):
/// pick a need type, then a mosque, and it is created already `APPROVED` —
/// water and equipment publish for funding at once, maintenance enters the
/// team leaders' claim queue.
///
/// Reached from the operations hub; each queue also has its own `+` button
/// straight to the matching form. The "published immediately" note leads as a
/// banner rather than a caption: skipping the approval step is the one thing
/// about this screen a manager must not miss.
class DirectProvisionHubScreen extends StatelessWidget {
  const DirectProvisionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.dpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 20,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextCustom(
                    text: l10n.dpDesc,
                    fontSize: 12.5,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OpsEntryCard(
            icon: Icons.water_drop_rounded,
            title: l10n.dpWater,
            description: l10n.dpWaterDesc,
            onTap: () => context.pushNamed(AppRoutes.opsDirectWaterName),
          ),
          OpsEntryCard(
            icon: Icons.kitchen_rounded,
            title: l10n.dpEquipment,
            description: l10n.dpEquipmentDesc,
            onTap: () => context.pushNamed(AppRoutes.opsDirectEquipmentName),
          ),
          OpsEntryCard(
            icon: Icons.build_rounded,
            title: l10n.dpMaintenance,
            description: l10n.dpMaintenanceDesc,
            onTap: () => context.pushNamed(AppRoutes.opsDirectMaintenanceName),
          ),
        ],
      ),
    );
  }
}

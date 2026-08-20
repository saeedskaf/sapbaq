import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/mosques/presentation/screens/most_needed_screen.dart';
import 'package:sapbaq/features/mosques/presentation/screens/mosque_picker_screen.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Asks where a donation goes and returns the chosen [DonationDestination], or
/// null if dismissed. Backs the "destination at add-time" flow: shown on the
/// first add-to-cart when no destination is set yet, and from the products chip.
///
/// **Both routes end on a real mosque.** "الأكثر حاجة" is no longer a pool that
/// hides the destination — it opens the admin's curated shortlist and the donor
/// picks one, so the mosque's name is known from here on (delivery §4).
Future<DonationDestination?> showDestinationPicker(BuildContext context) async {
  final choice = await showModalBottomSheet<_DestChoice>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DestinationPickerSheet(),
  );
  if (choice == null || !context.mounted) return null;
  return Navigator.of(context, rootNavigator: true).push<DonationDestination>(
    MaterialPageRoute(
      builder: (_) => switch (choice) {
        _DestChoice.mostNeeded => const MostNeededScreen(),
        _DestChoice.specificMosque => const MosquePickerScreen(),
      },
    ),
  );
}

enum _DestChoice { specificMosque, mostNeeded }

class _DestinationPickerSheet extends StatelessWidget {
  const _DestinationPickerSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextCustom.subheading(text: l10n.destinationPickerTitle),
              const SizedBox(height: 16),
              _DestOption(
                icon: Icons.mosque_rounded,
                title: l10n.destSpecificMosque,
                subtitle: l10n.destSpecificMosqueDesc,
                onTap: () => Navigator.pop(context, _DestChoice.specificMosque),
              ),
              const SizedBox(height: 12),
              _DestOption(
                icon: Icons.volunteer_activism_rounded,
                title: l10n.mostNeededShort,
                subtitle: l10n.mostNeededPickBody,
                onTap: () => Navigator.pop(context, _DestChoice.mostNeeded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DestOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
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
                    icon,
                    color: context.colors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextCustom(
                        text: title,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      TextCustom(
                        text: subtitle,
                        fontSize: 12.5,
                        color: context.colors.textSecondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: context.colors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

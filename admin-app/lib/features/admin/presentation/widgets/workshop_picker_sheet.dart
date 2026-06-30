import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/features/admin/data/models/workshop.dart';
import 'package:sapbaq_admin/features/shared/presentation/pill.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Bottom sheet listing staff (workshops/handlers or team leaders) to pick
/// from. Pops the chosen [Workshop]. Entries are sorted by lightest
/// [Workshop.activeLoad] first to help balance the load. [title] overrides the
/// default header (e.g. "choose a team leader" vs "choose a workshop").
class WorkshopPickerSheet extends StatelessWidget {
  final List<Workshop> workshops;
  final String? title;
  const WorkshopPickerSheet({super.key, required this.workshops, this.title});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = [...workshops]
      ..sort((a, b) => a.activeLoad.compareTo(b.activeLoad));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColorsCustom.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          TextCustom.subheading(text: title ?? l10n.chooseWorkshop),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                color: ColorsCustom.border,
              ),
              itemBuilder: (context, i) {
                final w = sorted[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(context).pop(w),
                  leading: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: ColorsCustom.secondaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.engineering_outlined,
                      color: ColorsCustom.primary,
                      size: 22,
                    ),
                  ),
                  title: TextCustom(
                    text: w.fullName,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: TextCustom(
                    text: w.phone,
                    fontSize: 12,
                    color: ColorsCustom.textSecondary,
                  ),
                  trailing: Pill(
                    text: l10n.workshopActiveLoad(w.activeLoad),
                    color: w.activeLoad == 0
                        ? ColorsCustom.success
                        : ColorsCustom.textSecondary,
                    background: ColorsCustom.surfaceVariant,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

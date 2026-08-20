import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/features/mosques/data/mosque_lookup_repository.dart';
import 'package:sapbaq_admin/features/mosques/presentation/widgets/mosque_browse_view.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// The mosque picker as a bottom sheet — [MosqueBrowseView] with a grabber and
/// a title. Resolves to the chosen mosque, or null when dismissed.
///
/// [pinnedGovernorate] scopes the whole browser to one governorate (a regional
/// manager's own); leave it null to browse all of them.
Future<PickableMosque?> showMosqueBrowseSheet(
  BuildContext context, {
  String? pinnedGovernorate,
}) {
  return showModalBottomSheet<PickableMosque>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: sheetContext.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              TextCustom.subheading(text: l10n.chooseMosque),
              Expanded(
                child: MosqueBrowseView(
                  pinnedGovernorate: pinnedGovernorate,
                  bottomPadding:
                      MediaQuery.of(sheetContext).padding.bottom + 16,
                  onMosqueTap: (mosque) =>
                      Navigator.of(sheetContext).pop(mosque),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

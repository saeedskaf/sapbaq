import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Placeholder tab screen for features not built yet.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: ColorsCustom.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: ColorsCustom.primary),
            ),
            const SizedBox(height: 20),
            TextCustom.subheading(text: l10n.comingSoon),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// "الأكثر حاجة" — the admin's tag on a mosque, shown **beside** its name and
/// never instead of it (delivery §4.3). Deliberately small and quiet: it marks
/// a mosque, it doesn't rename it.
class MostNeededBadge extends StatelessWidget {
  final double fontSize;
  const MostNeededBadge({super.key, this.fontSize = 10.5});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.primaryFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextCustom(
        text: l10n.mostNeededBadge,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: context.colors.onPrimary,
      ),
    );
  }
}

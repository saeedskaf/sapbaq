import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';

export 'package:sapbaq_admin/core/utils/month_filter.dart';

/// One choice in a [showFilterOptionsSheet]: the [value] sent to the server
/// (empty string = "any/all") and its localized [label].
class FilterOption {
  final String value;
  final String label;
  const FilterOption(this.value, this.label);
}

/// A compact, tappable filter pill (label + dropdown chevron) used across the
/// operations-center queues. Fill-based like [FilterTabs]: muted when at its
/// default value, tinted when an active filter is applied — so the user can see
/// at a glance whether a queue is filtered.
class FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
        decoration: BoxDecoration(
          color: active ? ColorsCustom.brandMint : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: active ? null : Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextCustom(
              text: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? ColorsCustom.onMint : colors.textSecondary,
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: active ? ColorsCustom.onMint : colors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontally-scrolling row of filter [pills], laid out under a queue's app
/// bar with the queue list's own horizontal padding.
class OpsFilterBar extends StatelessWidget {
  final List<Widget> pills;
  const OpsFilterBar({super.key, required this.pills});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: pills.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => pills[i],
        ),
      ),
    );
  }
}

/// A single-select options sheet. Returns the chosen [FilterOption.value], or
/// null if dismissed without choosing.
Future<String?> showFilterOptionsSheet(
  BuildContext context, {
  required String title,
  required List<FilterOption> options,
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            TextCustom.subheading(text: title),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in options)
                    ListTile(
                      title: TextCustom(text: o.label, fontSize: 14),
                      trailing: o.value == selected
                          ? Icon(
                              Icons.check_rounded,
                              color: context.colors.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(o.value),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

// --- Month label formatting (keys come from core/utils/month_filter.dart) ---

// Gregorian month names — the app renders dates with Western digits (see
// date_format.dart), so the year stays numeric here too. Kept local rather than
// via intl to avoid per-locale date-symbol initialization.
const _monthNamesAr = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];
const _monthNamesEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "يوليو 2026" / "July 2026" for a `YYYY-MM` [key] (returns [key] unchanged if
/// malformed).
String formatMonthKey(BuildContext context, String key) {
  final parts = key.split('-');
  if (parts.length != 2) return key;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) return key;
  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  final name = (isAr ? _monthNamesAr : _monthNamesEn)[month - 1];
  return '$name $year';
}

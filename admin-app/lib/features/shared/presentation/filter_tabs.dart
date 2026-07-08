import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';

/// A horizontal row of filter tabs (admin orders, driver deliveries). Only the
/// active tab is a solid pill; the rest are plain muted text — keeps the bar
/// quiet and the selection obvious. Scrolls horizontally when labels overflow.
class FilterTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const FilterTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? ColorsCustom.brandMint : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextCustom(
                text: labels[i],
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected
                    ? ColorsCustom.onMint
                    : ColorsCustom.textHint,
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';

/// Bordered card grouping selectable [SettingsOptionTile]s with hairline
/// dividers — matches the profile screen's tile-group styling.
class SettingsOptionGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingsOptionGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 60),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: context.colors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// A selectable settings row: leading icon chip, label, and a trailing check
/// when [selected]. Theme- and direction-aware.
class SettingsOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SettingsOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: context.colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextCustom(
                  text: label,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? context.colors.primary
                    : context.colors.textHint,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

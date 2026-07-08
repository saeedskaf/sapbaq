import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';

class ShowMessage {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? foregroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Default banner is the brand mint, which needs a dark foreground; the
    // saturated status fills (success/error) pass their own white foreground.
    final bg = backgroundColor ?? context.colors.primaryFill;
    final fg =
        foregroundColor ??
        (backgroundColor == null
            ? context.colors.onPrimary
            : ColorsCustom.textOnPrimary);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: TextCustom(
                text: message,
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: ColorsCustom.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: ColorsCustom.error,
      icon: Icons.error_outline_rounded,
    );
  }

  static void info(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: context.colors.primaryFill,
      foregroundColor: context.colors.onPrimary,
      icon: Icons.info_outline_rounded,
    );
  }
}

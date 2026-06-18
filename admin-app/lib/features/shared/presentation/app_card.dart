import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';

/// The one card surface used across the app: a borderless white panel lifted by
/// a single soft shadow (no hairline borders). Keeping every card identical is
/// what makes the screens read as calm and clean.
///
/// Pass [onTap] to make it tappable (with a ripple clipped to the rounded
/// corners).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final content = Padding(padding: padding, child: child);

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Material(
          color: color ?? ColorsCustom.surface,
          child: onTap == null
              ? content
              : InkWell(onTap: onTap, child: content),
        ),
      ),
    );

    if (margin != null) card = Padding(padding: margin!, child: card);
    return card;
  }
}

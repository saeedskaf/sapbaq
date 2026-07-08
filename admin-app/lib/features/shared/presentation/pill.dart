import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';

/// A small rounded, color-tinted label (status badge, chip, role tag).
class Pill extends StatelessWidget {
  final String text;

  /// Foreground (text) color. The background defaults to this color at low
  /// opacity unless [background] is given.
  final Color color;
  final Color? background;
  final double fontSize;
  final FontWeight fontWeight;
  final double hPad;
  final double vPad;
  final double radius;

  const Pill({
    super.key,
    required this.text,
    required this.color,
    this.background,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w700,
    this.hPad = 10,
    this.vPad = 5,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: TextCustom(
        text: text,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

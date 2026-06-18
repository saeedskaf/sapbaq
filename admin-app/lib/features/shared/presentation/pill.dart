import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';

/// A small rounded, color-tinted label (status badge, chip, role tag).
///
/// Tajawal sits high in its line box — it reserves extra descent space below the
/// glyphs — so symmetric padding makes Arabic look top-heavy. We bias the top
/// padding by ~0.25× the font size (e.g. +3px at 12px) so the glyphs read as
/// vertically centered. This is the one place that's handled, so every pill in
/// the app is consistent (and matches the customer app's status badge).
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
    final topBias = fontSize * 0.25;
    return Container(
      padding: EdgeInsets.fromLTRB(hPad, vPad + topBias, hPad, vPad),
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

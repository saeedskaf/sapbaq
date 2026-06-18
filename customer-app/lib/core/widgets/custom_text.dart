import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';

/// Text widget that auto-detects Arabic vs Latin script and applies the
/// matching font and direction. Arabic uses Tajawal, Latin uses Poppins.
///
/// When [color] is omitted the text resolves to a theme-aware default
/// (primary text color, or secondary for [TextCustom.caption]) so it stays
/// legible in both light and dark.
class TextCustom extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextOverflow overflow;
  final int? maxLines;
  final TextAlign textAlign;
  final TextDecoration? decoration;
  final double? letterSpacing;

  /// Whether the theme default (when [color] is null) is the secondary text
  /// color instead of the primary one.
  final bool _secondaryDefault;

  const TextCustom({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.color,
    this.fontWeight = FontWeight.w500,
    this.overflow = TextOverflow.visible,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.letterSpacing,
  }) : _secondaryDefault = false;

  const TextCustom.heading({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.color,
    this.fontWeight = FontWeight.w700,
    this.overflow = TextOverflow.visible,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.letterSpacing,
  }) : _secondaryDefault = false;

  const TextCustom.subheading({
    super.key,
    required this.text,
    this.fontSize = 18,
    this.color,
    this.fontWeight = FontWeight.w600,
    this.overflow = TextOverflow.visible,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.letterSpacing,
  }) : _secondaryDefault = false;

  const TextCustom.body({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.color,
    this.fontWeight = FontWeight.w400,
    this.overflow = TextOverflow.visible,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.letterSpacing,
  }) : _secondaryDefault = false;

  const TextCustom.caption({
    super.key,
    required this.text,
    this.fontSize = 12,
    this.color,
    this.fontWeight = FontWeight.w400,
    this.overflow = TextOverflow.visible,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.letterSpacing,
  }) : _secondaryDefault = true;

  TextStyle _arabicStyle(Color c) => GoogleFonts.tajawal(
    fontSize: fontSize,
    color: c,
    fontWeight: fontWeight,
    decoration: decoration,
    letterSpacing: letterSpacing ?? 0,
  ).copyWith(leadingDistribution: TextLeadingDistribution.even);

  TextStyle _latinStyle(Color c) => GoogleFonts.poppins(
    fontSize: fontSize,
    color: c,
    fontWeight: fontWeight,
    decoration: decoration,
    letterSpacing: letterSpacing ?? 0,
  ).copyWith(leadingDistribution: TextLeadingDistribution.even);

  @override
  Widget build(BuildContext context) {
    final hasArabic = text.contains(RegExp(r'[؀-ۿ]'));
    final effectiveColor = color ??
        (_secondaryDefault
            ? context.colors.textSecondary
            : context.colors.textPrimary);

    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
      style: hasArabic ? _arabicStyle(effectiveColor) : _latinStyle(effectiveColor),
    );
  }
}

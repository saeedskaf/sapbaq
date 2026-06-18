import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';

/// Text widget that auto-detects Arabic vs Latin script and applies the
/// matching font and direction. Arabic uses Tajawal, Latin uses Poppins.
class TextCustom extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final TextOverflow overflow;
  final int? maxLines;
  final TextAlign textAlign;
  final TextDecoration? decoration;
  final double? letterSpacing;

  const TextCustom({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.color = ColorsCustom.textPrimary,
    this.fontWeight = FontWeight.w500,
    this.overflow = TextOverflow.visible,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.letterSpacing,
  });

  const TextCustom.heading({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.color = ColorsCustom.textPrimary,
    this.fontWeight = FontWeight.w700,
    this.overflow = TextOverflow.visible,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.letterSpacing,
  });

  const TextCustom.subheading({
    super.key,
    required this.text,
    this.fontSize = 18,
    this.color = ColorsCustom.textPrimary,
    this.fontWeight = FontWeight.w600,
    this.overflow = TextOverflow.visible,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.letterSpacing,
  });

  const TextCustom.body({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.color = ColorsCustom.textPrimary,
    this.fontWeight = FontWeight.w400,
    this.overflow = TextOverflow.visible,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.letterSpacing,
  });

  const TextCustom.caption({
    super.key,
    required this.text,
    this.fontSize = 12,
    this.color = ColorsCustom.textSecondary,
    this.fontWeight = FontWeight.w400,
    this.overflow = TextOverflow.visible,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.letterSpacing,
  });

  TextStyle get _arabicStyle => GoogleFonts.tajawal(
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    decoration: decoration,
    letterSpacing: letterSpacing ?? 0,
  ).copyWith(leadingDistribution: TextLeadingDistribution.even);

  TextStyle get _latinStyle => GoogleFonts.poppins(
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    decoration: decoration,
    letterSpacing: letterSpacing ?? 0,
  ).copyWith(leadingDistribution: TextLeadingDistribution.even);

  @override
  Widget build(BuildContext context) {
    final hasArabic = text.contains(RegExp(r'[؀-ۿ]'));

    // The app is RTL: a text block must always start from the right edge. Keep
    // the per-script base direction (so Latin text and numbers still render
    // left-to-right internally, with no character reordering), but map the
    // default `start` alignment to the right so Latin-only text doesn't hug the
    // left. Explicit alignments (center/left/right) are respected as-is.
    final align = textAlign == TextAlign.start ? TextAlign.right : textAlign;

    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: align,
      textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
      style: hasArabic ? _arabicStyle : _latinStyle,
    );
  }
}

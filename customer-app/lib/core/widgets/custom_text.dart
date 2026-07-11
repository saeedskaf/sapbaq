import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';

/// Text widget that auto-detects Arabic vs Latin script and applies the
/// matching font and direction. Arabic UI text uses Cairo and Latin uses
/// Poppins; the brand wordmark ("ســـبّاقـــ") always renders in Tajawal, even
/// when it appears inside otherwise-Cairo Arabic copy. Each is rendered with
/// its natural metrics (no per-script height/baseline hacks).
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

  /// The canonical brand wordmark (the elongated logo form). Every recognized
  /// brand spelling is rendered as THIS string in Tajawal, so the name always
  /// matches the logo — even when CMS/content text spells it plainly.
  static const String brandWordmark = 'ســـبّاقـــ';

  /// Brand spellings that normalize to [brandWordmark]. The brand is "سبّاق"
  /// (front-runner, always written with a shadda), so we match the shadda'd
  /// forms and the elongated logo form; the plain word "سباق" ("race", no
  /// shadda) is intentionally excluded so ordinary prose is left untouched.
  static final RegExp _brandPattern = RegExp(
    [brandWordmark, 'سَبّاق', 'سبّاق'].map(RegExp.escape).join('|'),
  );

  TextStyle _arabicStyle(Color c) => GoogleFonts.cairo(
    fontSize: fontSize,
    color: c,
    fontWeight: fontWeight,
    decoration: decoration,
    letterSpacing: letterSpacing ?? 0,
  );

  TextStyle _brandStyle(Color c) => GoogleFonts.tajawal(
    fontSize: fontSize,
    color: c,
    fontWeight: fontWeight,
    decoration: decoration,
    letterSpacing: letterSpacing ?? 0,
  );

  TextStyle _latinStyle(Color c) => GoogleFonts.poppins(
    fontSize: fontSize,
    color: c,
    fontWeight: fontWeight,
    decoration: decoration,
    letterSpacing: letterSpacing ?? 0,
  );

  @override
  Widget build(BuildContext context) {
    final hasArabic = text.contains(RegExp(r'[؀-ۿ]'));
    final effectiveColor =
        color ??
        (_secondaryDefault
            ? context.colors.textSecondary
            : context.colors.textPrimary);

    final baseStyle = hasArabic
        ? _arabicStyle(effectiveColor)
        : _latinStyle(effectiveColor);

    // Render any brand spelling as the Tajawal wordmark even when embedded in
    // Cairo Arabic text (e.g. "مرحبًا بك في ســـبّاقـــ").
    if (hasArabic && _brandPattern.hasMatch(text)) {
      return Text.rich(
        _brandSpans(baseStyle, _brandStyle(effectiveColor)),
        overflow: overflow,
        maxLines: maxLines,
        textAlign: textAlign,
        textDirection: TextDirection.rtl,
      );
    }

    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
      style: baseStyle,
    );
  }

  /// Splits [text] so each recognized brand spelling (see [_brandPattern])
  /// renders as the canonical [brandWordmark] in [brandStyle] (Tajawal), while
  /// the surrounding copy keeps [baseStyle].
  TextSpan _brandSpans(TextStyle baseStyle, TextStyle brandStyle) {
    final spans = <TextSpan>[];
    var last = 0;
    for (final match in _brandPattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(
          TextSpan(text: text.substring(last, match.start), style: baseStyle),
        );
      }
      spans.add(TextSpan(text: brandWordmark, style: brandStyle));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: baseStyle));
    }
    return TextSpan(children: spans);
  }
}

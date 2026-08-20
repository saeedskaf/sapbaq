import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';

/// A small rounded label — status badge, chip, role tag.
///
/// The rendering follows the palette's one rule for coloured surfaces: a
/// **signal** colour (mint / amber / red) is painted solid and labelled by
/// [ColorsCustom.onSignal], while a neutral stays quiet on a grey fill. The
/// old treatment —
/// the colour at 14% behind the same colour as text — could not survive the
/// move to the logo's mint, and was already failing contrast on amber
/// (2.4:1) long before that.
class Pill extends StatelessWidget {
  final String text;

  /// The status colour. Becomes the fill when it is a signal, the label when
  /// it is a neutral.
  final Color color;

  /// Overrides the computed fill. The label still follows the rule above.
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
    final signal = ColorsCustom.isSignal(color);
    final fill = background ?? (signal ? color : context.colors.surfaceVariant);
    final foreground = signal ? ColorsCustom.onSignal(color) : color;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: TextCustom(
        text: text,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: foreground,
      ),
    );
  }
}

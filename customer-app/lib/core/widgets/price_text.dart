import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';

/// The pre-discount price, struck through — the "was" beside the "now".
///
/// One widget for every surface that shows one (product card, detail sheet,
/// cart line, cart summary), because the four used to disagree on all three
/// things that matter: the size (11pt to 14pt), whether the currency was
/// repeated, and how visible the rule was.
///
/// Two decisions are baked in here rather than left to call sites:
///
/// * **The rule is drawn at [_ruleThickness], not the font's own.** Fonts put
///   the strikeout at roughly 5% of the em, so under ~14pt it lands beneath a
///   single device pixel and antialiases to nothing. On a light card a faint
///   dark line still registers; on a near-black one a faint light line does
///   not, which is why the strike-through read as simply missing in dark mode.
/// * **The number is bare — no "د.ك".** The live price next to it carries the
///   currency; repeating it doubles the width of the row inside a 141pt card
///   and pushes the price that customers actually pay into an ellipsis.
class StruckPrice extends StatelessWidget {
  /// The list price as a bare number, exactly as the server sent it.
  final String amount;

  final double fontSize;

  const StruckPrice({super.key, required this.amount, this.fontSize = 13});

  /// Doubling the font's hairline puts the rule back above one device pixel
  /// at every size this widget is used at.
  static const double _ruleThickness = 2;

  @override
  Widget build(BuildContext context) {
    // Red, and the theme-aware one: the palette's `error` is tuned to read on
    // a white card (4.83:1) and drops to 3.71:1 on a dark one, which would
    // have traded a grey that was hard to see for a red that was harder.
    final danger = context.colors.danger;
    return TextCustom(
      text: amount,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: danger,
      decoration: TextDecoration.lineThrough,
      decorationColor: danger,
      decorationThickness: _ruleThickness,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

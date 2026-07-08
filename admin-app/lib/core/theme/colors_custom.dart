import 'package:flutter/material.dart';

/// Sapbaq design system palette.
///
/// Derived from the Sapbaq (سَبّاق) logo: deep race-green as the anchor, the
/// logo's fresh mint as the lively accent, soft off-white surfaces, and a
/// restrained gold used only for premium highlights.
class ColorsCustom {
  ColorsCustom._();

  // Brand — deep green (speed, freshness, trust)
  static const Color primary = Color(0xFF1F7A52);
  static const Color primaryDark = Color(0xFF14573A);
  static const Color primaryLight = Color(0xFF4FA87D);

  // Logo mint — the exact flat green of the logo mark (sampled from the
  // customer app's assets/images/logo/sapbaq_logo_mark.png). This is the
  // brand's primary fill: buttons and highlighted surfaces use it with
  // [onMint] on top.
  static const Color brandMint = Color(0xFF87CDAA);

  /// Foreground on [brandMint] fills — brand near-black green.
  static const Color onMint = Color(0xFF06130D);

  // Accent — warm gold
  static const Color secondary = Color(0xFFCFA13E);
  static const Color secondaryLight = Color(0xFFDCF2E6);

  // Premium highlight — subtle gold (use sparingly)
  static const Color accentGold = Color(0xFFC9A24B);

  // Neutrals / surfaces — soft off-white
  static const Color background = Color(0xFFF5F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDF4F0);
  static const Color border = Color(0xFFE0E9E4);

  // Subtle mint tint applied to inputs while focused
  static const Color inputFocusFill = Color(0xFFEFF9F3);

  // Text
  static const Color textPrimary = Color(0xFF122E22);
  static const Color textSecondary = Color(0xFF5A6B62);
  static const Color textHint = Color(0xFF97A69D);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF2E9E6B);
  static const Color warning = Color(0xFFE0A33E);
  static const Color error = Color(0xFFC8463C);
  static const Color info = Color(0xFF2BB7C6);

  // Soft brand gradient for hero areas (splash, headers).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}

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

  // Logo mint — the brand mark's chevron color
  static const Color brandMint = Color(0xFF8ACCAB);

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

  // ── Dark theme palette ────────────────────────────────────────────────────
  // Anchored on the brand near-black (#101513) used by the launcher icon.
  static const Color darkBackground = Color(0xFF0F1411);
  static const Color darkSurface = Color(0xFF161D19);
  static const Color darkSurfaceVariant = Color(0xFF1E2823);
  static const Color darkBorder = Color(0xFF2C3832);

  static const Color darkTextPrimary = Color(0xFFEAF2ED);
  static const Color darkTextSecondary = Color(0xFFA4B5AB);
  static const Color darkTextHint = Color(0xFF6E7F76);

  /// Brand green brightened to the logo mint so it stays legible as a
  /// foreground (text/icons/borders) on dark surfaces.
  static const Color primaryOnDark = Color(0xFF5FB98C);

  /// Foreground on the (brightened) primary in dark mode.
  static const Color darkOnPrimary = Color(0xFF06130D);

  /// Subtle green-tinted chip/fill on dark (the dark counterpart of the mint
  /// [secondaryLight] tint used for icon chips).
  static const Color darkPrimaryTint = Color(0xFF1C2D25);
}

import 'package:flutter/material.dart';

/// Sapbaq design system palette.
///
/// Derived from the Sapbaq (سَبّاق) logo: deep race-green as the anchor, the
/// logo's fresh mint as the lively accent, soft off-white surfaces, and a
/// restrained gold used only for premium highlights.
class ColorsCustom {
  ColorsCustom._();

  // Brand — a single mint hue expressed as a tonal ramp. The logo mint is the
  // hero fill; [primary] is the accessible deep-mint foreground on light
  // surfaces (replaces the former off-logo green #1F7A52 so brand text/icons
  // clear WCAG AA on white).
  static const Color primary = Color(0xFF0E5E44);
  static const Color primaryDark = Color(0xFF14573A);
  static const Color primaryLight = Color(0xFF4FA87D);

  // Logo mint — the exact flat green of the logo mark (sampled from the
  // customer app's assets/images/logo/sapbaq_logo_mark.png). This is the
  // brand's primary fill: buttons and highlighted surfaces use it with
  // [onMint] on top.
  static const Color brandMint = Color(0xFF87CDAA);

  /// Foreground on [brandMint] fills — brand near-black green.
  static const Color onMint = Color(0xFF06130D);

  /// Near-black brand anchor for immersive surfaces (splash, auth headers).
  /// The logo's dark is pure black; this is a hair lighter for OLED comfort.
  static const Color ink = Color(0xFF0B0F0D);

  // Mint tint — chip / selected-row / icon-chip wash on light surfaces.
  static const Color secondaryLight = Color(0xFFDCF2E6);

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

  // Status — reduced to the international essentials. Success is a brand-hue
  // green; only amber (warning) and red (error) stay as distinct signals.
  static const Color success = Color(0xFF2E9E6B);
  static const Color warning = Color(0xFFE0A33E);
  static const Color error = Color(0xFFC8463C);

  // ── Dark theme palette ────────────────────────────────────────────────────
  // Anchored on the brand near-black (#101513) used by the launcher icon.
  static const Color darkBackground = Color(0xFF0F1411);
  static const Color darkSurface = Color(0xFF161D19);
  static const Color darkSurfaceVariant = Color(0xFF1E2823);
  static const Color darkBorder = Color(0xFF2C3832);

  static const Color darkTextPrimary = Color(0xFFEAF2ED);
  static const Color darkTextSecondary = Color(0xFFA4B5AB);
  static const Color darkTextHint = Color(0xFF6E7F76);

  /// Brand green on dark surfaces — the exact logo mint, which is light
  /// enough to work as both foreground (text/icons) and fill on dark.
  static const Color primaryOnDark = brandMint;

  /// Foreground on mint fills. Alias of [onMint], kept for dark-palette
  /// symmetry.
  static const Color darkOnPrimary = onMint;

  /// Subtle green-tinted chip/fill on dark (the dark counterpart of the mint
  /// [secondaryLight] tint used for icon chips).
  static const Color darkPrimaryTint = Color(0xFF1C2D25);
}

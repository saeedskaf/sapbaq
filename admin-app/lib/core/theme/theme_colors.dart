import 'package:flutter/material.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';

/// Theme-aware design tokens that flip between light and dark.
///
/// These preserve the app's design vocabulary (`surface` vs `background` vs
/// `surfaceVariant` vs `primaryTint`…) which the Material [ColorScheme] can't
/// express 1:1. Registered on both themes and read via `context.colors`, so a
/// widget written as `context.colors.surface` automatically resolves to the
/// right color for the active brightness.
///
/// Mode-independent colors intentionally stay on [ColorsCustom]: the status
/// signals (error/success/warning), the map markers, the logo lockup's mint,
/// and [ColorsCustom.brandMint] — a mint state pill is identical in both
/// modes, so it never flips and its foreground is fixed dark.
@immutable
class ThemeColors extends ThemeExtension<ThemeColors> {
  const ThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.primary,
    required this.primaryFill,
    required this.onPrimary,
    required this.inputFocusFill,
    required this.imageWell,
    required this.danger,
  });

  /// Scaffold / screen background.
  final Color background;

  /// Card / sheet / app-bar fill.
  final Color surface;

  /// Subtle filled areas (input fields, chips, inactive fills).
  final Color surfaceVariant;

  /// Hairline borders and dividers.
  final Color border;

  /// Primary text and high-emphasis icons.
  final Color textPrimary;

  /// Secondary text.
  final Color textSecondary;

  /// Hint / disabled / tertiary text.
  final Color textHint;

  /// The strong foreground (text/icons/borders) on neutral surfaces —
  /// monochrome: ink on light, near-white on dark. Not a brand hue.
  final Color primary;

  /// Fill behind [onPrimary] content (buttons, FAB, active controls) — the
  /// logo mint, at one value, in both modes. It needs no light/dark variant:
  /// mint carries dark content at 11.34:1 on either ground, so the primary
  /// action looks identical wherever it appears.
  final Color primaryFill;

  /// Foreground placed on top of [primaryFill] — the inverse of [primaryFill].
  final Color onPrimary;

  /// Fill applied to inputs while focused.
  final Color inputFocusFill;

  /// The well behind `contain`-fitted product/model photos. Fixed light in
  /// both themes — see [ColorsCustom.imageWell].
  final Color imageWell;

  /// The alarm red as a **foreground** — destructive text and icons. It flips
  /// because a red that reads on a white card is too dark to read on a
  /// near-black one; see [ColorsCustom.errorOnDark]. Signal *fills* do not
  /// flip: they stay [ColorsCustom.error] in both modes and carry white.
  final Color danger;

  static const ThemeColors light = ThemeColors(
    background: ColorsCustom.background,
    surface: ColorsCustom.surface,
    surfaceVariant: ColorsCustom.surfaceVariant,
    border: ColorsCustom.border,
    textPrimary: ColorsCustom.textPrimary,
    textSecondary: ColorsCustom.textSecondary,
    textHint: ColorsCustom.textHint,
    primary: ColorsCustom.primary,
    primaryFill: ColorsCustom.brandMint,
    onPrimary: ColorsCustom.onMint,
    inputFocusFill: ColorsCustom.inputFocusFill,
    imageWell: ColorsCustom.imageWell,
    danger: ColorsCustom.error,
  );

  static const ThemeColors dark = ThemeColors(
    background: ColorsCustom.darkBackground,
    surface: ColorsCustom.darkSurface,
    surfaceVariant: ColorsCustom.darkSurfaceVariant,
    border: ColorsCustom.darkBorder,
    textPrimary: ColorsCustom.darkTextPrimary,
    textSecondary: ColorsCustom.darkTextSecondary,
    textHint: ColorsCustom.darkTextHint,
    primary: ColorsCustom.primaryOnDark,
    primaryFill: ColorsCustom.brandMint,
    onPrimary: ColorsCustom.onMint,
    inputFocusFill: ColorsCustom.darkSurfaceVariant,
    imageWell: ColorsCustom.imageWell,
    danger: ColorsCustom.errorOnDark,
  );

  @override
  ThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? primary,
    Color? primaryFill,
    Color? onPrimary,
    Color? inputFocusFill,
    Color? imageWell,
    Color? danger,
  }) {
    return ThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      primary: primary ?? this.primary,
      primaryFill: primaryFill ?? this.primaryFill,
      onPrimary: onPrimary ?? this.onPrimary,
      inputFocusFill: inputFocusFill ?? this.inputFocusFill,
      imageWell: imageWell ?? this.imageWell,
      danger: danger ?? this.danger,
    );
  }

  @override
  ThemeColors lerp(ThemeColors? other, double t) {
    if (other == null) return this;
    return ThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryFill: Color.lerp(primaryFill, other.primaryFill, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      inputFocusFill: Color.lerp(inputFocusFill, other.inputFocusFill, t)!,
      imageWell: Color.lerp(imageWell, other.imageWell, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// `context.colors.surface` — the active [ThemeColors] for this build context.
extension ThemeColorsX on BuildContext {
  ThemeColors get colors => Theme.of(this).extension<ThemeColors>()!;
}

import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';

/// Theme-aware design tokens that flip between light and dark.
///
/// These preserve the app's design vocabulary (`surface` vs `background` vs
/// `surfaceVariant` vs `primaryTint`…) which the Material [ColorScheme] can't
/// express 1:1. Registered on both themes and read via `context.colors`, so a
/// widget written as `context.colors.surface` automatically resolves to the
/// right color for the active brightness.
///
/// Brand-fixed colors (error/success/gold/gradient, white-on-brand fills, map
/// markers) intentionally stay on [ColorsCustom] — they look identical in both
/// themes.
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
    required this.primaryTint,
    required this.inputFocusFill,
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

  /// Brand green as a foreground (text/icons/borders) on neutral surfaces:
  /// deep green on light for contrast, the logo mint on dark.
  final Color primary;

  /// Brand fill behind [onPrimary] content (buttons, highlighted chips,
  /// active controls) — the exact logo mint in both modes.
  final Color primaryFill;

  /// Foreground placed on top of [primaryFill] — brand near-black green.
  final Color onPrimary;

  /// Tinted chip background behind primary-colored icons (the mint chip).
  final Color primaryTint;

  /// Fill applied to inputs while focused.
  final Color inputFocusFill;

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
    primaryTint: ColorsCustom.secondaryLight,
    inputFocusFill: ColorsCustom.inputFocusFill,
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
    onPrimary: ColorsCustom.darkOnPrimary,
    primaryTint: ColorsCustom.darkPrimaryTint,
    inputFocusFill: ColorsCustom.darkSurfaceVariant,
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
    Color? primaryTint,
    Color? inputFocusFill,
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
      primaryTint: primaryTint ?? this.primaryTint,
      inputFocusFill: inputFocusFill ?? this.inputFocusFill,
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
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t)!,
      inputFocusFill: Color.lerp(inputFocusFill, other.inputFocusFill, t)!,
    );
  }
}

/// `context.colors.surface` — the active [ThemeColors] for this build context.
extension ThemeColorsX on BuildContext {
  ThemeColors get colors => Theme.of(this).extension<ThemeColors>()!;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';

/// Builds the app's [ThemeData] for both brightnesses from a single
/// brightness-parameterized builder, so light and dark stay in lockstep and
/// only differ by their resolved neutral/brand tokens.
class AppTheme {
  AppTheme._();

  /// Status-bar overlay for light surfaces (dark icons).
  static const statusBarStyleLight = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  /// Status-bar overlay for dark surfaces (light icons).
  static const statusBarStyleDark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static final _borderRadius = BorderRadius.circular(12);
  static final _buttonBorderRadius = BorderRadius.circular(14);

  static ThemeData get light => _themeFor(Brightness.light);
  static ThemeData get dark => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Resolved neutral tokens for this brightness.
    final background =
        isDark ? ColorsCustom.darkBackground : ColorsCustom.background;
    final surface = isDark ? ColorsCustom.darkSurface : ColorsCustom.surface;
    final surfaceVariant =
        isDark ? ColorsCustom.darkSurfaceVariant : ColorsCustom.surfaceVariant;
    final border = isDark ? ColorsCustom.darkBorder : ColorsCustom.border;
    final textPrimary =
        isDark ? ColorsCustom.darkTextPrimary : ColorsCustom.textPrimary;
    final textSecondary =
        isDark ? ColorsCustom.darkTextSecondary : ColorsCustom.textSecondary;
    final textHint = isDark ? ColorsCustom.darkTextHint : ColorsCustom.textHint;

    // Brand: primary is brightened on dark so it stays legible as a foreground.
    final primary = isDark ? ColorsCustom.primaryOnDark : ColorsCustom.primary;
    final onPrimary =
        isDark ? ColorsCustom.darkOnPrimary : ColorsCustom.textOnPrimary;
    final primaryTint =
        isDark ? ColorsCustom.darkPrimaryTint : ColorsCustom.secondaryLight;

    final overlayStyle = isDark ? statusBarStyleDark : statusBarStyleLight;

    // Arabic-first: Tajawal renders Arabic cleanly and has a modern feel.
    final textTheme = GoogleFonts.tajawalTextTheme()
        .apply(bodyColor: textPrimary, displayColor: textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: <ThemeExtension<dynamic>>[
        isDark ? ThemeColors.dark : ThemeColors.light,
      ],
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: ColorsCustom.secondary,
        onSecondary: onPrimary,
        tertiary: primaryTint,
        onTertiary: textPrimary,
        surface: surface,
        onSurface: textPrimary,
        error: ColorsCustom.error,
        onError: ColorsCustom.textOnPrimary,
        outline: border,
        surfaceContainerHighest: surfaceVariant,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        systemOverlayStyle: overlayStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: border,
          disabledForegroundColor: textHint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: _buttonBorderRadius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: _buttonBorderRadius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return surface;
        }),
        side: BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.error, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textHint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 0.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surfaceVariant : ColorsCustom.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? textPrimary : ColorsCustom.surface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: _borderRadius),
      ),
    );
  }
}

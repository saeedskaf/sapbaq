import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';

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
    final background = isDark
        ? ColorsCustom.darkBackground
        : ColorsCustom.background;
    final surface = isDark ? ColorsCustom.darkSurface : ColorsCustom.surface;
    final surfaceVariant = isDark
        ? ColorsCustom.darkSurfaceVariant
        : ColorsCustom.surfaceVariant;
    final border = isDark ? ColorsCustom.darkBorder : ColorsCustom.border;
    final textPrimary = isDark
        ? ColorsCustom.darkTextPrimary
        : ColorsCustom.textPrimary;
    final textSecondary = isDark
        ? ColorsCustom.darkTextSecondary
        : ColorsCustom.textSecondary;
    final textHint = isDark ? ColorsCustom.darkTextHint : ColorsCustom.textHint;

    // The primary action is the logo's mint with a black label, identical in
    // both modes — the mint carries black at 11.3:1 on either ground. Only
    // the neutral foreground below flips.
    final primary = isDark ? ColorsCustom.primaryOnDark : ColorsCustom.primary;
    // Every brand fill is the one mint, in both modes.
    const primaryFill = ColorsCustom.brandMint;
    const onPrimary = ColorsCustom.onMint;

    // The alarm red as a foreground. `ColorScheme.error` is what Material
    // paints error text, helper text and error borders in, all of them read
    // against a surface rather than labelled — so it takes the end that suits
    // the ground. Solid signal fills are unaffected; they stay
    // `ColorsCustom.error` at their call sites.
    final danger = isDark ? ColorsCustom.errorOnDark : ColorsCustom.error;

    final overlayStyle = isDark ? statusBarStyleDark : statusBarStyleLight;

    // Arabic-first: Cairo (Arabic UI) + Poppins (Latin), each used with its
    // natural metrics — no per-script height/baseline hacks. The brand wordmark
    // stays in Tajawal via TextCustom, independent of this base theme.
    final textTheme = GoogleFonts.cairoTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

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
        secondary: ColorsCustom.brandMint,
        onSecondary: ColorsCustom.onMint,
        tertiary: surfaceVariant,
        onTertiary: textPrimary,
        surface: surface,
        onSurface: textPrimary,
        error: danger,
        // Inverted with it: the light-mode red is dark enough to carry white,
        // the dark-mode one is light enough to need black.
        onError: isDark ? ColorsCustom.black : ColorsCustom.white,
        outline: border,
        surfaceContainerHighest: surfaceVariant,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        // Seamless with the scaffold background — no hard line under the bar.
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        systemOverlayStyle: overlayStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryFill,
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
            return primaryFill;
          }
          return surface;
        }),
        checkColor: WidgetStatePropertyAll(onPrimary),
        side: BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? surface : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primaryFill : null,
        ),
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
        // Focus is a state, so the ring is mint — this is what puts the hue
        // on the login screen and on every form in the app.
        focusedBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(
            color: ColorsCustom.brandMint,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: BorderSide(color: danger, width: 1.5),
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
        backgroundColor: primaryFill,
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

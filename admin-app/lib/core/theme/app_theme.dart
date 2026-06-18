import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';

class AppTheme {
  AppTheme._();

  static const statusBarStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  static final _borderRadius = BorderRadius.circular(12);
  static final _buttonBorderRadius = BorderRadius.circular(14);

  static ThemeData get light {
    // Arabic-first: Tajawal renders Arabic cleanly and has a modern feel.
    final textTheme = GoogleFonts.tajawalTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ColorsCustom.background,
      colorScheme: const ColorScheme.light(
        primary: ColorsCustom.primary,
        secondary: ColorsCustom.secondary,
        tertiary: ColorsCustom.secondaryLight,
        surface: ColorsCustom.surface,
        error: ColorsCustom.error,
        onPrimary: ColorsCustom.textOnPrimary,
        onSecondary: ColorsCustom.textOnPrimary,
        outline: ColorsCustom.border,
        surfaceContainerHighest: ColorsCustom.surfaceVariant,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        // Seamless with the scaffold background — no hard line under the bar.
        backgroundColor: ColorsCustom.background,
        foregroundColor: ColorsCustom.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: ColorsCustom.textPrimary,
        ),
        systemOverlayStyle: statusBarStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsCustom.primary,
          foregroundColor: ColorsCustom.textOnPrimary,
          disabledBackgroundColor: ColorsCustom.border,
          disabledForegroundColor: ColorsCustom.textHint,
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
          foregroundColor: ColorsCustom.primary,
          side: const BorderSide(color: ColorsCustom.primary, width: 1.5),
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
          foregroundColor: ColorsCustom.primary,
          textStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorsCustom.primary;
          }
          return ColorsCustom.surface;
        }),
        side: const BorderSide(color: ColorsCustom.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorsCustom.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.error, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: ColorsCustom.textHint),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: ColorsCustom.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: ColorsCustom.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ColorsCustom.border, width: 0.5),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorsCustom.primary,
        foregroundColor: ColorsCustom.textOnPrimary,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: ColorsCustom.border,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorsCustom.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: _borderRadius),
      ),
    );
  }
}

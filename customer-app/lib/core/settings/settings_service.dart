import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sapbaq/core/constants/app_constants.dart';

/// Persists non-sensitive UI preferences (theme mode + language) in
/// [SharedPreferences].
///
/// Loaded once at startup ([create]) so the very first frame already reflects
/// the user's choice — no flash of the wrong theme or language.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const String _kThemeMode = 'settings.theme_mode';
  static const String _kLanguage = 'settings.language';

  /// Supported UI languages. Arabic is the default (Arabic-first app).
  static const List<String> supportedLanguages = ['ar', 'en'];

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  // --- Theme mode -----------------------------------------------------------

  /// Defaults to [ThemeMode.system] ("Match device") on first launch; users can
  /// pin Light or Dark explicitly from the Appearance screen.
  ThemeMode get themeMode {
    switch (_prefs.getString(_kThemeMode)) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_kThemeMode, mode.name);

  // --- Language -------------------------------------------------------------

  /// The selected UI locale, defaulting to Arabic on first run.
  Locale get locale {
    final code = _prefs.getString(_kLanguage);
    if (code != null && supportedLanguages.contains(code)) {
      return Locale(code);
    }
    return const Locale(AppConstants.defaultLanguageCode);
  }

  Future<void> setLocale(Locale locale) =>
      _prefs.setString(_kLanguage, locale.languageCode);
}

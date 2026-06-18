/// Non-localized, app-wide constants.
class AppConstants {
  AppConstants._();

  /// Sapbaq operates in Kuwait — default the phone country picker accordingly.
  static const String defaultCountryCode = 'KW';

  /// Default UI language on first launch (Arabic-first app). Users can switch
  /// to English in settings; the chosen locale also drives the layout
  /// direction (RTL for Arabic, LTR for English).
  static const String defaultLanguageCode = 'ar';
}

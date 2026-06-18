/// Typed references to bundled asset paths. Use these instead of raw strings.
class AppAssets {
  AppAssets._();

  static const String _logoDir = 'assets/images/logo';

  /// Sapbaq (سَبّاق) — full lockup (Arabic + Latin wordmark with the arrow mark).
  /// `OnDark` keeps the white text for dark/colored fills; `OnLight` uses
  /// dark-ink text for white/light surfaces.
  static const String logoFullOnDark = '$_logoDir/sapbaq_logo_full_on_dark.png';
  static const String logoFullOnLight =
      '$_logoDir/sapbaq_logo_full_on_light.png';

  /// Sapbaq arrow mark only (chevrons + dots + speed lines).
  static const String logoMarkOnDark = '$_logoDir/sapbaq_logo_mark_on_dark.png';
  static const String logoMarkOnLight =
      '$_logoDir/sapbaq_logo_mark_on_light.png';

  /// Monochrome all-white mark — for watermarks on brand-colored fills.
  static const String logoMarkWhite = '$_logoDir/sapbaq_logo_mark_white.png';
}

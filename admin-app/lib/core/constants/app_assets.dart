/// Typed references to bundled asset paths. Use these instead of raw strings.
class AppAssets {
  AppAssets._();

  static const String _logoDir = 'assets/images/logo';

  /// Sapbaq brand lockup — a self-contained card (baked background). The admin
  /// app ships the reversed variant (green card, black arrows, white wordmark +
  /// dots + dashes) to distinguish it from the customer app. Because the card
  /// carries its own background it is used as-is in BOTH light and dark mode.
  static const String logoFull = '$_logoDir/sapbaq_logo_full.png';

  /// The same lockup WITHOUT the wordmark (the launch-icon mark: arrows + dots
  /// + dashes on the brand card).
  static const String logoMark = '$_logoDir/sapbaq_logo_mark.png';
}

/// Typed references to bundled asset paths. Use these instead of raw strings.
class AppAssets {
  AppAssets._();

  static const String _logoDir = 'assets/images/logo';

  /// Sapbaq brand lockup — a self-contained card (baked background). The
  /// customer app ships the primary variant (black card, green arrows, white
  /// wordmark + dots + dashes). Because the card carries its own background it
  /// is used as-is in BOTH light and dark mode — no theme switching.
  static const String logoFull = '$_logoDir/sapbaq_logo_full.png';

  /// The same lockup WITHOUT the wordmark (the launch-icon mark: arrows + dots
  /// + dashes on the brand card). Used in-app only for the video-proof cover.
  static const String logoMark = '$_logoDir/sapbaq_logo_mark.png';
}

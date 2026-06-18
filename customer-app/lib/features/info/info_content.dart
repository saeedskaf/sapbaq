/// Static contact details and app metadata used by the Contact / About pages.
///
/// Long-form copy (about / privacy / terms / FAQ) now comes from the CMS
/// (`GET /content/{slug}/`), so it no longer lives here.
class InfoContent {
  InfoContent._();

  // --- App ---
  static const String appVersion = '1.0.0';

  // --- Contact ---
  static const String supportPhone = '+96562224195';
  static const String supportWhatsapp = '+96562224195';
  static const String supportEmail = 'Info@big.com.kw';
}

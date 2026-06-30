/// Static app metadata and the built-in contact fallback.
///
/// Long-form copy (about / privacy / terms / FAQ) comes from the CMS
/// (`GET /content/{slug}/`), and the live contact details come from
/// `GET /content/contact/`. These constants are only the fallback shown until
/// that responds (and if it has no entry).
class InfoContent {
  InfoContent._();

  // --- App ---
  static const String appVersion = '1.0.0';

  // --- Contact fallback (live values come from GET /content/contact/) ---
  static const String supportPhone = '+96562224195';
  static const String supportWhatsapp = '+96562224195';
  static const String supportEmail = 'info@albairakgroup.com';
}

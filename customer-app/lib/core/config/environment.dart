/// App environment configuration.
///
/// Override at build/run time, e.g.:
///   flutter run --dart-define=BASE_URL=https://staging.example.com/api/v1
class Environment {
  Environment._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://sapbaq.albairakgroup.com/api/v1',
  );

  /// Whether this is a non-production (staging/dev) build. Defaults to `false`
  /// so release builds are production by default; opt in for staging with
  /// `--dart-define=DEV_MODE=true`. OTP is delivered over real SMS in all
  /// environments — there is no in-app code display.
  static const bool devMode = bool.fromEnvironment('DEV_MODE');

  /// Where the MyFatoorah hosted page sends the customer back on success /
  /// failure — the server's `MYFATOORAH_CALLBACK_URL` / `MYFATOORAH_ERROR_URL`
  /// (backend answers §1). MyFatoorah only appends `?paymentId=…&Id=…`, so a
  /// prefix match is enough.
  ///
  /// These only tell the in-app browser **when to close** — the outcome always
  /// comes from `POST /payments/confirm/`, which re-queries the gateway. So a
  /// stale value degrades to "the customer closes the page himself", never to a
  /// wrong result.
  static const String payCallbackUrl = String.fromEnvironment(
    'PAY_CALLBACK_URL',
    defaultValue: 'https://sapbaq.albairakgroup.com/pay/success',
  );
  static const String payErrorUrl = String.fromEnvironment(
    'PAY_ERROR_URL',
    defaultValue: 'https://sapbaq.albairakgroup.com/pay/failed',
  );

  /// Our own page hosting MyFatoorah's embedded card fields — the card route
  /// (FLUTTER_PAYMENTS_SPEC_2026-08-10 §3-٢).
  ///
  /// Defaulted rather than left blank, which is a reversal worth recording. It
  /// shipped empty on purpose while the page was unproven: an address that 404s
  /// strands customers in an empty sheet, and the hosted page has never stopped
  /// working. The backend has since measured the page live — it is served, the
  /// library loads through the CSP, and the card iframe renders against our own
  /// session — and diagnosed what was actually failing before: `execute` being
  /// called before the bridge said `collected`, which the gateway reports as an
  /// invalid session. The sheet no longer does that.
  ///
  /// So the default is now the real page, and the empty build is the override
  /// rather than the norm. **Setting this to an empty string switches the whole
  /// app back to the hosted page** — one `--dart-define` away, which is the
  /// rollback if the embedded route misbehaves in the field.
  ///
  /// KNET and Apple Pay still take the hosted page regardless: neither can be
  /// embedded (§1, §8-أ).
  static const String payEmbedUrl = String.fromEnvironment(
    'PAY_EMBED_URL',
    defaultValue: 'https://sapbaq.albairakgroup.com/pay/embed/',
  );

  /// Whether the in-app card sheet may be used at all.
  static bool get embeddedCheckoutEnabled => payEmbedUrl.isNotEmpty;

  /// Google OAuth **Web/Server** client ID (Firebase project `sapbaq`). Passed
  /// to `google_sign_in` as `serverClientId` so the returned `id_token`'s
  /// audience matches what the backend validates against.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '113479519511-8duqipsb74s99892jc7mcp3raf9pmnhd.apps.googleusercontent.com',
  );
}

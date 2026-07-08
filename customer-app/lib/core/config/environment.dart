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

  /// Google OAuth **Web/Server** client ID (Firebase project `sapbaq`). Passed
  /// to `google_sign_in` as `serverClientId` so the returned `id_token`'s
  /// audience matches what the backend validates against.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '113479519511-8duqipsb74s99892jc7mcp3raf9pmnhd.apps.googleusercontent.com',
  );
}

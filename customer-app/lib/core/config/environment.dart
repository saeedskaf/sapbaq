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
}

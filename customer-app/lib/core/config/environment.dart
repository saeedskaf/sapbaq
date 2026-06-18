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

  /// Whether the backend is running in dev mode (returns `dev_code` for OTP,
  /// mock payments, etc.). Drives dev-only UI affordances.
  static const bool devMode = bool.fromEnvironment('DEV_MODE', defaultValue: true);
}

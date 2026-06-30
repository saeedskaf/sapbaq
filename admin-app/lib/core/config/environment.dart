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
  /// `--dart-define=DEV_MODE=true`.
  static const bool devMode = bool.fromEnvironment('DEV_MODE');

  /// Whether to initialize Firebase + push notifications. On by default now that
  /// the Firebase project is linked (Android google-services / iOS APNs).
  /// Disable for a Firebase-less run (e.g. an emulator without Google Play
  /// Services) with: flutter run --dart-define=PUSH_ENABLED=false
  static const bool pushEnabled = bool.fromEnvironment(
    'PUSH_ENABLED',
    defaultValue: true,
  );
}

import 'dart:async';

/// Onboarding/entry gates layered on top of a valid session:
/// - [completingProfile]: signed in but the account isn't usable yet — verify a
///   phone (if missing) and complete name/email.
/// - [settingPasscode]: profile done but no 4-digit passcode set yet.
/// - [locked]: a fully set-up session persisted from a previous launch — must be
///   unlocked with biometrics or the passcode before the app opens.
enum AuthStatus {
  unknown,
  authenticated,
  completingProfile,
  settingPasscode,
  locked,
  unauthenticated,
  guest,
}

/// App-wide session signal.
///
/// The Dio auth interceptor pushes [AuthStatus.unauthenticated] when token
/// refresh fails; the auth repository pushes status on login/logout. AuthBloc
/// and the router listen to [stream].
class SessionManager {
  AuthStatus _status = AuthStatus.unknown;
  final _controller = StreamController<AuthStatus>.broadcast();

  AuthStatus get status => _status;
  Stream<AuthStatus> get stream => _controller.stream;

  void setStatus(AuthStatus status) {
    _status = status;
    _controller.add(status);
  }

  void authenticated() => setStatus(AuthStatus.authenticated);
  void completingProfile() => setStatus(AuthStatus.completingProfile);
  void settingPasscode() => setStatus(AuthStatus.settingPasscode);
  void locked() => setStatus(AuthStatus.locked);
  void unauthenticated() => setStatus(AuthStatus.unauthenticated);
  void guest() => setStatus(AuthStatus.guest);

  void dispose() => _controller.close();
}

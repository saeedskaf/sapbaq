import 'dart:async';

/// [completingProfile]: signed in (valid tokens) but the account isn't usable
/// yet — the user must verify a phone and/or complete their profile first.
enum AuthStatus {
  unknown,
  authenticated,
  completingProfile,
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
  void unauthenticated() => setStatus(AuthStatus.unauthenticated);
  void guest() => setStatus(AuthStatus.guest);

  void dispose() => _controller.close();
}

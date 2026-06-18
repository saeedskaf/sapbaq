import 'dart:async';

enum AuthStatus { unknown, authenticated, unauthenticated, guest }

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
  void unauthenticated() => setStatus(AuthStatus.unauthenticated);
  void guest() => setStatus(AuthStatus.guest);

  void dispose() => _controller.close();
}

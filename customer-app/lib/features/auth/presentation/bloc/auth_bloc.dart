import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/data/models/user.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// User chose to browse without an account.
class AuthGuestRequested extends AuthEvent {
  const AuthGuestRequested();
}

/// Re-reads the cached user into state (e.g. after a profile update).
class AuthUserRefreshed extends AuthEvent {
  const AuthUserRefreshed();
}

class _AuthStatusChanged extends AuthEvent {
  final AuthStatus status;
  const _AuthStatusChanged(this.status);
  @override
  List<Object?> get props => [status];
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;

  const AuthState({this.status = AuthStatus.unknown, this.user});

  @override
  List<Object?> get props => [status, user];
}

/// App-wide session bloc. Observes [AuthRepository.status] and exposes the
/// current [User]. Drives router redirects.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  StreamSubscription<AuthStatus>? _sub;

  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthSubscriptionRequested>(_onSubscribe);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthGuestRequested>(_onGuestRequested);
    on<AuthUserRefreshed>(_onUserRefreshed);
    on<_AuthStatusChanged>(_onStatusChanged);
  }

  Future<void> _onSubscribe(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) async {
    _sub ??= _repo.status.listen((status) => add(_AuthStatusChanged(status)));
    await _repo.bootstrap();
  }

  Future<void> _onStatusChanged(
    _AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    switch (event.status) {
      case AuthStatus.authenticated:
        emit(
          AuthState(
            status: AuthStatus.authenticated,
            user: await _repo.cachedUser(),
          ),
        );
      case AuthStatus.unauthenticated:
        emit(const AuthState(status: AuthStatus.unauthenticated));
      case AuthStatus.guest:
        emit(const AuthState(status: AuthStatus.guest));
      case AuthStatus.unknown:
        emit(const AuthState(status: AuthStatus.unknown));
    }
  }

  Future<void> _onUserRefreshed(
    AuthUserRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status != AuthStatus.authenticated) return;
    emit(
      AuthState(
        status: AuthStatus.authenticated,
        user: await _repo.cachedUser(),
      ),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.logout();
  }

  Future<void> _onGuestRequested(
    AuthGuestRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.enterGuest();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

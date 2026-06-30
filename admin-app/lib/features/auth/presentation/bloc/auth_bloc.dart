import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/features/auth/data/auth_repository.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';

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
/// current [User] (whose `user_type` drives admin/driver routing).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  StreamSubscription<AuthStatus>? _sub;

  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthSubscriptionRequested>(_onSubscribe);
    on<AuthLogoutRequested>(_onLogout);
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
        // Refresh from the server so role/level/governorate/permission fields
        // are current (the login payload is slim); fall back to the cached
        // profile when offline.
        final user = await _tryGetMe() ?? await _repo.cachedUser();
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      case AuthStatus.unauthenticated:
        emit(const AuthState(status: AuthStatus.unauthenticated));
      case AuthStatus.guest:
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

  Future<User?> _tryGetMe() async {
    try {
      return await _repo.getMe();
    } on ApiException {
      return null;
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

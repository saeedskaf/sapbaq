import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/data/passkey_service.dart';

/// Which sign-in action is in flight (drives per-button spinners).
enum LoginAction { none, google, apple, otp, passkey }

class LoginState extends Equatable {
  /// The action currently running, or [LoginAction.none] when idle.
  final LoginAction busy;

  /// Set once an OTP was sent, so the screen navigates to the code step.
  final bool otpSent;

  /// The phone the OTP was sent to (carried to the OTP screen).
  final String? phone;

  final String? message;
  final String? phoneError;

  /// A platform passkey failure the screen maps to a localized message.
  final PasskeyFailure? passkeyFailure;

  /// An unexpected sign-in failure — the screen shows a generic localized error.
  final bool failed;

  const LoginState({
    this.busy = LoginAction.none,
    this.otpSent = false,
    this.phone,
    this.message,
    this.phoneError,
    this.passkeyFailure,
    this.failed = false,
  });

  bool get isBusy => busy != LoginAction.none;

  @override
  List<Object?> get props => [
    busy,
    otpSent,
    phone,
    message,
    phoneError,
    passkeyFailure,
    failed,
  ];
}

/// Drives the login screen: Google/Apple sign-in and requesting a phone OTP.
///
/// Social sign-in publishes the session through [AuthRepository] (the router
/// reacts), so on success this cubit just clears its busy state. A cancelled
/// native sheet returns quietly to idle.
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repo;
  LoginCubit(this._repo) : super(const LoginState());

  Future<void> signInWithGoogle() =>
      _social(LoginAction.google, _repo.signInWithGoogle);

  Future<void> signInWithApple() =>
      _social(LoginAction.apple, _repo.signInWithApple);

  Future<void> _social(
    LoginAction action,
    Future<Object?> Function() run,
  ) async {
    emit(LoginState(busy: action));
    try {
      await run();
      // Success → repo updated the session; router navigates. Null → cancelled.
      emit(const LoginState());
    } on ApiException catch (e) {
      emit(LoginState(message: e.message));
    } catch (e, st) {
      debugPrint('Social sign-in ($action) failed: $e\n$st');
      emit(const LoginState(failed: true));
    }
  }

  Future<void> requestOtp({required String phone}) async {
    emit(const LoginState(busy: LoginAction.otp));
    try {
      await _repo.requestOtp(phone: phone);
      emit(LoginState(otpSent: true, phone: phone));
    } on ApiException catch (e) {
      emit(LoginState(message: e.message, phoneError: e.fieldError('phone')));
    }
  }

  /// Sign in with a device passkey. On success the repository publishes the
  /// session (router navigates); a cancelled sheet returns quietly to idle.
  Future<void> signInWithPasskey() async {
    emit(const LoginState(busy: LoginAction.passkey));
    try {
      await _repo.loginWithPasskey();
      emit(const LoginState());
    } on ApiException catch (e) {
      emit(LoginState(message: e.message));
    } on PasskeyException catch (e) {
      emit(LoginState(passkeyFailure: e.reason));
    } catch (e, st) {
      debugPrint('Passkey sign-in failed: $e\n$st');
      emit(const LoginState(failed: true));
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

/// Which sign-in action is in flight (drives per-button spinners).
enum LoginAction { none, check, google, apple }

/// Where the number check sends the user next — one screen, two outcomes.
enum LoginNav {
  none,

  /// Registered with a passcode → enter the passcode (no OTP).
  passcode,

  /// Not registered, or registered without a passcode → an OTP was just sent.
  otp,
}

class LoginState extends Equatable {
  final LoginAction busy;
  final LoginNav nav;

  /// The number the flow continues with (carried to the next screen).
  final String? phone;

  final String? message;
  final String? phoneError;

  /// An unexpected sign-in failure — the screen shows a generic localized error.
  final bool failed;

  const LoginState({
    this.busy = LoginAction.none,
    this.nav = LoginNav.none,
    this.phone,
    this.message,
    this.phoneError,
    this.failed = false,
  });

  bool get isBusy => busy != LoginAction.none;

  @override
  List<Object?> get props => [busy, nav, phone, message, phoneError, failed];
}

/// Drives the login screen: the number check (which decides passcode vs OTP),
/// plus Google/Apple sign-in. Social sign-in publishes the session through
/// [AuthRepository] (the router reacts); the number check hands navigation back
/// to the screen via [LoginState.nav].
class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repo;
  LoginCubit(this._repo) : super(const LoginState());

  /// Ask the server what to do with [phone]: go straight to the passcode when
  /// it's a set-up account, otherwise send an OTP (sign-up, or a legacy account
  /// that still needs a passcode) and route to the code step.
  Future<void> checkNumber({required String phone}) async {
    emit(LoginState(busy: LoginAction.check, phone: phone));
    try {
      final status = await _repo.checkNumber(phone: phone);
      if (status.registered && status.passcodeSet) {
        emit(LoginState(nav: LoginNav.passcode, phone: phone));
      } else {
        await _repo.requestOtp(phone: phone);
        emit(LoginState(nav: LoginNav.otp, phone: phone));
      }
    } on ApiException catch (e) {
      emit(LoginState(message: e.message, phoneError: e.fieldError('phone')));
    }
  }

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
}

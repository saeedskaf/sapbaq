import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

/// Result of a passcode attempt that the screen must react to.
enum PasscodeOutcome {
  none,

  /// This device isn't trusted (428) → run the device-trust flow.
  deviceUntrusted,

  /// The passcode is locked after 5 wrong tries (423) → run forgot-passcode.
  locked,
}

class PasscodeLoginState extends Equatable {
  final bool busy;
  final PasscodeOutcome outcome;

  /// True when the code was wrong but the account isn't locked yet — the screen
  /// shows a localized "wrong passcode" message and lets the user retry.
  final bool wrongPasscode;

  /// A network/other error message to surface as-is.
  final String? message;

  const PasscodeLoginState({
    this.busy = false,
    this.outcome = PasscodeOutcome.none,
    this.wrongPasscode = false,
    this.message,
  });

  @override
  List<Object?> get props => [busy, outcome, wrongPasscode, message];
}

/// Verifies the daily-login passcode on a trusted device. On success the
/// repository publishes the session and the router navigates; failures map to a
/// [PasscodeOutcome] (device trust / forgot) or a wrong-passcode retry.
class PasscodeLoginCubit extends Cubit<PasscodeLoginState> {
  final AuthRepository _repo;
  PasscodeLoginCubit(this._repo) : super(const PasscodeLoginState());

  Future<void> login({required String phone, required String passcode}) async {
    emit(const PasscodeLoginState(busy: true));
    try {
      await _repo.passcodeLogin(phone: phone, passcode: passcode);
      // Success → session published; router/AuthBloc navigates.
    } on ApiException catch (e) {
      switch (e.statusCode) {
        case 428:
          emit(const PasscodeLoginState(outcome: PasscodeOutcome.deviceUntrusted));
        case 423:
          emit(const PasscodeLoginState(outcome: PasscodeOutcome.locked));
        case 0:
          emit(PasscodeLoginState(message: e.message));
        default:
          emit(const PasscodeLoginState(wrongPasscode: true));
      }
    }
  }
}

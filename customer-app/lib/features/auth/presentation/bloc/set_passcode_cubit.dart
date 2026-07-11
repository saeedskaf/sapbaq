import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

/// Onboarding steps for setting the passcode.
enum SetPasscodeStep {
  /// Entering the 4 digits the first time.
  enter,

  /// Re-entering to confirm.
  confirm,

  /// Passcode saved; offering the biometric opt-in (skipped when unavailable).
  biometric,
}

class SetPasscodeState extends Equatable {
  final SetPasscodeStep step;
  final bool busy;

  /// True when this device can offer Face ID / Touch ID (decided on open).
  final bool biometricAvailable;

  final String? message;

  const SetPasscodeState({
    this.step = SetPasscodeStep.enter,
    this.busy = false,
    this.biometricAvailable = false,
    this.message,
  });

  SetPasscodeState copyWith({
    SetPasscodeStep? step,
    bool? busy,
    bool? biometricAvailable,
    String? message,
  }) {
    return SetPasscodeState(
      step: step ?? this.step,
      busy: busy ?? this.busy,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      message: message,
    );
  }

  @override
  List<Object?> get props => [step, busy, biometricAvailable, message];
}

/// Sets the 4-digit passcode (enter → confirm), then offers the biometric
/// opt-in before opening the app. Weak-passcode rejection is done in the screen
/// (instant feedback); the backend enforces its own policy.
class SetPasscodeCubit extends Cubit<SetPasscodeState> {
  final AuthRepository _repo;
  SetPasscodeCubit(this._repo) : super(const SetPasscodeState());

  Future<void> init() async {
    emit(state.copyWith(biometricAvailable: await _repo.biometricAvailable()));
  }

  /// Advance from the first entry to the confirm step.
  void toConfirm() => emit(state.copyWith(step: SetPasscodeStep.confirm));

  /// Return to the first entry (e.g. the two entries didn't match).
  void restart() => emit(state.copyWith(step: SetPasscodeStep.enter));

  /// Persist the confirmed passcode, then move to the biometric opt-in — or
  /// finish straight away when biometrics aren't available.
  Future<void> submit({required String passcode}) async {
    emit(state.copyWith(busy: true, message: null));
    try {
      await _repo.setPasscode(passcode: passcode);
      if (state.biometricAvailable) {
        emit(state.copyWith(busy: false, step: SetPasscodeStep.biometric));
      } else {
        _repo.completePasscodeSetup();
      }
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, message: e.message, step: SetPasscodeStep.enter));
    }
  }

  /// Enable (or skip) biometric unlock, then open the app.
  Future<void> finish({required bool enableBiometric}) async {
    if (enableBiometric) {
      await _repo.setBiometricEnabled(true);
    }
    _repo.completePasscodeSetup();
  }
}

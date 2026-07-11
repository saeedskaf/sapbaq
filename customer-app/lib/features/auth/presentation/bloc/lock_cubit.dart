import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

class UnlockState extends Equatable {
  final bool busy;

  /// Whether biometric unlock should be offered (available + opted-in).
  final bool biometricEnabled;

  /// True after a wrong passcode entry (not locked yet).
  final bool wrongPasscode;

  /// The passcode is locked (423) → the screen routes to forgot-passcode.
  final bool locked;

  final String? message;

  const UnlockState({
    this.busy = false,
    this.biometricEnabled = false,
    this.wrongPasscode = false,
    this.locked = false,
    this.message,
  });

  UnlockState copyWith({
    bool? busy,
    bool? biometricEnabled,
    bool? wrongPasscode,
    bool? locked,
    String? message,
  }) {
    return UnlockState(
      busy: busy ?? this.busy,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      wrongPasscode: wrongPasscode ?? this.wrongPasscode,
      locked: locked ?? this.locked,
      message: message,
    );
  }

  @override
  List<Object?> get props =>
      [busy, biometricEnabled, wrongPasscode, locked, message];
}

/// The app-entry gate for a persisted session ([AuthStatus.locked]). Biometrics
/// release the stored session locally; the passcode (server-verified) is the
/// fallback. "Use different account" logs out.
class LockCubit extends Cubit<UnlockState> {
  final AuthRepository _repo;
  final String phone;

  LockCubit(this._repo, {required this.phone}) : super(const UnlockState());

  /// Decide whether to show the biometric affordance, then (if so) prompt once.
  Future<void> init({required String reason}) async {
    final available = await _repo.biometricAvailable();
    final enabled = available && await _repo.biometricEnabled();
    emit(state.copyWith(biometricEnabled: enabled));
    if (enabled) await unlockWithBiometrics(reason: reason);
  }

  Future<void> unlockWithBiometrics({required String reason}) async {
    emit(state.copyWith(busy: true, message: null));
    final ok = await _repo.unlockWithBiometrics(reason: reason);
    // Success → session authenticated (router navigates). Otherwise fall back to
    // the passcode silently.
    if (!ok) emit(state.copyWith(busy: false));
  }

  Future<void> unlockWithPasscode({required String passcode}) async {
    emit(state.copyWith(busy: true, message: null, wrongPasscode: false));
    try {
      await _repo.passcodeLogin(phone: phone, passcode: passcode);
      // Success → session published; router/AuthBloc navigates.
    } on ApiException catch (e) {
      switch (e.statusCode) {
        case 423:
          emit(state.copyWith(busy: false, locked: true));
        case 0:
          emit(state.copyWith(busy: false, message: e.message));
        default:
          emit(state.copyWith(busy: false, wrongPasscode: true));
      }
    }
  }

  void logout() => _repo.logout();
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

class DeviceTrustState extends Equatable {
  final bool busy;

  /// True once the OTP has been sent at least once (drives the resend cooldown).
  final bool codeSent;

  final String? message;

  const DeviceTrustState({
    this.busy = false,
    this.codeSent = false,
    this.message,
  });

  DeviceTrustState copyWith({bool? busy, bool? codeSent, String? message}) {
    return DeviceTrustState(
      busy: busy ?? this.busy,
      codeSent: codeSent ?? this.codeSent,
      message: message,
    );
  }

  @override
  List<Object?> get props => [busy, codeSent, message];
}

/// Trusts a new/unrecognized device (428): sends an OTP, verifies it, then
/// retries the carried passcode so the login completes without re-typing it.
class DeviceTrustCubit extends Cubit<DeviceTrustState> {
  final AuthRepository _repo;
  final String phone;
  final String passcode;

  DeviceTrustCubit(this._repo, {required this.phone, required this.passcode})
      : super(const DeviceTrustState());

  /// Send (or resend) the device-trust OTP.
  Future<void> sendCode() async {
    emit(state.copyWith(busy: true, message: null));
    try {
      await _repo.deviceTrustRequest(phone: phone);
      emit(state.copyWith(busy: false, codeSent: true));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, message: e.message));
    }
  }

  /// Verify the OTP → trust the device → retry the passcode login. On success
  /// the repository publishes the session and the router navigates.
  Future<void> verify({required String code}) async {
    emit(state.copyWith(busy: true, message: null));
    try {
      await _repo.deviceTrustVerify(phone: phone, code: code);
      await _repo.passcodeLogin(phone: phone, passcode: passcode);
      // Success → session published; router/AuthBloc navigates.
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, message: e.message));
    }
  }
}

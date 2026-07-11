import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

class ForgotPasscodeState extends Equatable {
  final bool busy;
  final bool codeSent;
  final String? message;

  const ForgotPasscodeState({
    this.busy = false,
    this.codeSent = false,
    this.message,
  });

  ForgotPasscodeState copyWith({bool? busy, bool? codeSent, String? message}) {
    return ForgotPasscodeState(
      busy: busy ?? this.busy,
      codeSent: codeSent ?? this.codeSent,
      message: message,
    );
  }

  @override
  List<Object?> get props => [busy, codeSent, message];
}

/// Passcode recovery: send an OTP, then set a new passcode with it. A successful
/// reset unlocks and signs in (the repository publishes the session).
class ForgotPasscodeCubit extends Cubit<ForgotPasscodeState> {
  final AuthRepository _repo;
  final String phone;

  ForgotPasscodeCubit(this._repo, {required this.phone})
      : super(const ForgotPasscodeState());

  Future<void> sendCode() async {
    emit(state.copyWith(busy: true, message: null));
    try {
      await _repo.forgotPasscodeRequest(phone: phone);
      emit(state.copyWith(busy: false, codeSent: true));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, message: e.message));
    }
  }

  Future<void> reset({
    required String code,
    required String newPasscode,
  }) async {
    emit(state.copyWith(busy: true, message: null));
    try {
      await _repo.forgotPasscodeReset(
        phone: phone,
        code: code,
        newPasscode: newPasscode,
      );
      // Success → session published; router/AuthBloc navigates.
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, message: e.message));
    }
  }
}

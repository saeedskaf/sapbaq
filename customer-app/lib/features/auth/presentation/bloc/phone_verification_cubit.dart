import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

/// Two-step phone verification for a social user who signed in without a phone.
enum PhoneStep { enterPhone, enterCode }

class PhoneVerificationState extends Equatable {
  final PhoneStep step;
  final bool busy;

  /// The phone being verified (set once the code is requested).
  final String? phone;

  /// Set when the code is confirmed → the screen advances to profile completion.
  final bool verified;

  final String? message;
  final String? phoneError;

  const PhoneVerificationState({
    this.step = PhoneStep.enterPhone,
    this.busy = false,
    this.phone,
    this.verified = false,
    this.message,
    this.phoneError,
  });

  PhoneVerificationState copyWith({
    PhoneStep? step,
    bool? busy,
    String? phone,
    bool? verified,
    String? message,
    String? phoneError,
  }) {
    return PhoneVerificationState(
      step: step ?? this.step,
      busy: busy ?? this.busy,
      phone: phone ?? this.phone,
      verified: verified ?? this.verified,
      message: message,
      phoneError: phoneError,
    );
  }

  @override
  List<Object?> get props => [step, busy, phone, verified, message, phoneError];
}

class PhoneVerificationCubit extends Cubit<PhoneVerificationState> {
  final AuthRepository _repo;
  PhoneVerificationCubit(this._repo) : super(const PhoneVerificationState());

  Future<void> requestCode({required String phone}) async {
    emit(state.copyWith(busy: true, phoneError: null, message: null));
    try {
      await _repo.requestPhone(phone: phone);
      emit(state.copyWith(busy: false, step: PhoneStep.enterCode, phone: phone));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          busy: false,
          message: e.message,
          phoneError: e.fieldError('phone'),
        ),
      );
    }
  }

  Future<void> verify({required String code}) async {
    final phone = state.phone;
    if (phone == null) return;
    emit(state.copyWith(busy: true, message: null));
    try {
      await _repo.verifyPhone(phone: phone, code: code);
      emit(state.copyWith(busy: false, verified: true));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, message: e.message));
    }
  }

  /// Return to the number step to correct a mistyped phone.
  void editPhone() => emit(state.copyWith(step: PhoneStep.enterPhone));
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

class SignupState extends Equatable {
  final FormStatus status;
  final String? message;
  final String? phoneError;
  final String phone;

  /// Dev-only OTP returned by the backend (no real SMS in dev); null in prod.
  final String? devCode;

  const SignupState({
    this.status = FormStatus.initial,
    this.message,
    this.phoneError,
    this.phone = '',
    this.devCode,
  });

  @override
  List<Object?> get props => [status, message, phoneError, phone, devCode];
}

class SignupCubit extends Cubit<SignupState> {
  final AuthRepository _repo;
  SignupCubit(this._repo) : super(const SignupState());

  Future<void> submit({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    emit(const SignupState(status: FormStatus.submitting));
    try {
      final devCode = await _repo.signup(
        phone: phone,
        fullName: fullName,
        password: password,
      );
      emit(
        SignupState(
          status: FormStatus.success,
          phone: phone,
          devCode: devCode,
        ),
      );
    } on ApiException catch (e) {
      emit(
        SignupState(
          status: FormStatus.failure,
          message: e.message,
          phoneError: e.fieldError('phone'),
        ),
      );
    }
  }
}

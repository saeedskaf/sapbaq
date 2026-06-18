import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

class LoginState extends Equatable {
  final FormStatus status;
  final String? message;
  final String? phoneError;

  const LoginState({
    this.status = FormStatus.initial,
    this.message,
    this.phoneError,
  });

  @override
  List<Object?> get props => [status, message, phoneError];
}

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repo;
  LoginCubit(this._repo) : super(const LoginState());

  Future<void> submit({required String phone, required String password}) async {
    emit(const LoginState(status: FormStatus.submitting));
    try {
      await _repo.login(phone: phone, password: password);
      emit(const LoginState(status: FormStatus.success));
    } on ApiException catch (e) {
      emit(
        LoginState(
          status: FormStatus.failure,
          message: e.message,
          phoneError: e.fieldError('phone'),
        ),
      );
    }
  }
}

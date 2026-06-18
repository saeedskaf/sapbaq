import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

class ForgotPasswordState extends Equatable {
  final FormStatus status;
  final String? message;
  final String phone;

  const ForgotPasswordState({
    this.status = FormStatus.initial,
    this.message,
    this.phone = '',
  });

  @override
  List<Object?> get props => [status, message, phone];
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _repo;
  ForgotPasswordCubit(this._repo) : super(const ForgotPasswordState());

  Future<void> submit({required String phone}) async {
    emit(const ForgotPasswordState(status: FormStatus.submitting));
    try {
      await _repo.forgotPassword(phone: phone);
      emit(ForgotPasswordState(status: FormStatus.success, phone: phone));
    } on ApiException catch (e) {
      emit(
        ForgotPasswordState(status: FormStatus.failure, message: e.message),
      );
    }
  }
}

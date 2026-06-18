import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

class ResetPasswordState extends Equatable {
  final FormStatus status;
  final String? message;

  const ResetPasswordState({this.status = FormStatus.initial, this.message});

  @override
  List<Object?> get props => [status, message];
}

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  final AuthRepository _repo;
  ResetPasswordCubit(this._repo) : super(const ResetPasswordState());

  Future<void> submit({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    emit(const ResetPasswordState(status: FormStatus.submitting));
    try {
      await _repo.resetPassword(
        phone: phone,
        code: code,
        newPassword: newPassword,
      );
      emit(const ResetPasswordState(status: FormStatus.success));
    } on ApiException catch (e) {
      emit(ResetPasswordState(status: FormStatus.failure, message: e.message));
    }
  }
}

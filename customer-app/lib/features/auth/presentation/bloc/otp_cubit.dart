import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

class OtpState extends Equatable {
  final FormStatus status;
  final String? message;

  const OtpState({this.status = FormStatus.initial, this.message});

  @override
  List<Object?> get props => [status, message];
}

class OtpCubit extends Cubit<OtpState> {
  final AuthRepository _repo;
  OtpCubit(this._repo) : super(const OtpState());

  Future<void> verify({required String phone, required String code}) async {
    emit(const OtpState(status: FormStatus.submitting));
    try {
      await _repo.verifyOtp(phone: phone, code: code);
      emit(const OtpState(status: FormStatus.success));
    } on ApiException catch (e) {
      emit(OtpState(status: FormStatus.failure, message: e.message));
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

class ProfileCompletionState extends Equatable {
  final FormStatus status;
  final String? message;
  final String? emailError;

  const ProfileCompletionState({
    this.status = FormStatus.initial,
    this.message,
    this.emailError,
  });

  @override
  List<Object?> get props => [status, message, emailError];
}

/// Submits the final onboarding step (name + email). On success the repository
/// flips the session to authenticated and the router opens the app.
class ProfileCompletionCubit extends Cubit<ProfileCompletionState> {
  final AuthRepository _repo;
  ProfileCompletionCubit(this._repo) : super(const ProfileCompletionState());

  Future<void> submit({
    required String firstName,
    required String lastName,
    String? middleName,
    required String email,
  }) async {
    emit(const ProfileCompletionState(status: FormStatus.submitting));
    try {
      await _repo.completeProfile(
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        email: email,
      );
      emit(const ProfileCompletionState(status: FormStatus.success));
    } on ApiException catch (e) {
      emit(
        ProfileCompletionState(
          status: FormStatus.failure,
          message: e.message,
          emailError: e.fieldError('email'),
        ),
      );
    }
  }
}

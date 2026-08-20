import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/maintenance_case.dart';

/// Loads a single maintenance case and runs its lifecycle actions; every action
/// returns the full updated case, which replaces [item]. [dirty] flags whether
/// any action succeeded, so the queue can refresh when the detail pops.
class MaintenanceDetailState extends Equatable {
  final LoadStatus status;
  final MaintenanceCase? item;
  final bool busy;
  final bool dirty;
  final String? message;

  const MaintenanceDetailState({
    this.status = LoadStatus.initial,
    this.item,
    this.busy = false,
    this.dirty = false,
    this.message,
  });

  MaintenanceDetailState copyWith({
    LoadStatus? status,
    MaintenanceCase? item,
    bool? busy,
    bool? dirty,
    String? message,
  }) {
    return MaintenanceDetailState(
      status: status ?? this.status,
      item: item ?? this.item,
      busy: busy ?? this.busy,
      dirty: dirty ?? this.dirty,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, item, busy, dirty, message];
}

class MaintenanceDetailCubit extends Cubit<MaintenanceDetailState> {
  final AdminRepository _repo;
  final int caseId;
  MaintenanceDetailCubit(this._repo, this.caseId)
    : super(const MaintenanceDetailState());

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, message: null));
    try {
      final item = await _repo.fetchMaintenanceCase(caseId);
      emit(state.copyWith(status: LoadStatus.success, item: item));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  Future<bool> _run(Future<MaintenanceCase> Function() action) async {
    emit(state.copyWith(busy: true, message: null));
    try {
      final updated = await action();
      emit(
        state.copyWith(
          item: updated,
          busy: false,
          dirty: true,
          status: LoadStatus.success,
        ),
      );
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, message: e.message));
      return false;
    }
  }

  Future<bool> acknowledge() => _run(() => _repo.acknowledgeCase(caseId));

  Future<bool> setPriority(String priority) =>
      _run(() => _repo.setCasePriority(caseId, priority));

  Future<bool> approve({required String costPath, String? price}) =>
      _run(() => _repo.approveCase(caseId, costPath: costPath, price: price));

  Future<bool> assignTeamLeader(int teamLeaderId) =>
      _run(() => _repo.assignCaseTeamLeader(caseId, teamLeaderId));

  Future<bool> assignMember(int memberId) =>
      _run(() => _repo.assignCaseMember(caseId, memberId));

  Future<bool> complete(String statement, List<String> photoPaths) => _run(
    () => _repo.completeCase(
      caseId,
      statement: statement,
      photoPaths: photoPaths,
    ),
  );

  Future<bool> verify() => _run(() => _repo.verifyCase(caseId));

  /// Team leader pulls this unassigned approved case onto his own team.
  Future<bool> claim() => _run(() => _repo.claimCase(caseId));

  Future<bool> duplicate(int targetCaseId) =>
      _run(() => _repo.duplicateCase(caseId, targetCaseId: targetCaseId));

  Future<bool> cancel(String? reason) =>
      _run(() => _repo.cancelCase(caseId, reason: reason));
}

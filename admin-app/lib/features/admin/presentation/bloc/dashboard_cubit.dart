import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/dashboard_summary.dart';

class DashboardState extends Equatable {
  final LoadStatus status;
  final DashboardSummary? summary;
  final String? message;

  const DashboardState({
    this.status = LoadStatus.initial,
    this.summary,
    this.message,
  });

  DashboardState copyWith({
    LoadStatus? status,
    DashboardSummary? summary,
    String? message,
  }) {
    return DashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, summary, message];
}

class DashboardCubit extends Cubit<DashboardState> {
  final AdminRepository _repo;
  DashboardCubit(this._repo) : super(const DashboardState());

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, message: null));
    try {
      final summary = await _repo.fetchDashboard();
      emit(state.copyWith(status: LoadStatus.success, summary: summary));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }
}

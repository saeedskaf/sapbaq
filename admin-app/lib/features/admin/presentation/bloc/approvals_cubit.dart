import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/approval.dart';

class ApprovalsState extends Equatable {
  final LoadStatus status;
  final List<Approval> items;
  final bool hasMore;
  final bool loadingMore;

  /// The approval currently being approved/rejected, so its card can show a
  /// spinner. Null when idle. (Always overwritten on copyWith.)
  final int? actioningId;
  final String? message;

  const ApprovalsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.actioningId,
    this.message,
  });

  ApprovalsState copyWith({
    LoadStatus? status,
    List<Approval>? items,
    bool? hasMore,
    bool? loadingMore,
    int? actioningId,
    String? message,
  }) {
    return ApprovalsState(
      status: status ?? this.status,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      actioningId: actioningId,
      message: message,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, hasMore, loadingMore, actioningId, message];
}

class ApprovalsCubit extends Cubit<ApprovalsState> {
  final AdminRepository _repo;
  ApprovalsCubit(this._repo) : super(const ApprovalsState());

  int _page = 1;

  Future<void> load() async {
    _page = 1;
    emit(state.copyWith(
      status: LoadStatus.loading,
      items: const [],
      loadingMore: false,
      message: null,
    ));
    try {
      final page = await _repo.fetchApprovals(page: 1);
      emit(state.copyWith(
        status: LoadStatus.success,
        items: page.results,
        hasMore: page.hasMore,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore ||
        !state.hasMore ||
        state.status != LoadStatus.success) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repo.fetchApprovals(page: _page + 1);
      _page += 1;
      emit(state.copyWith(
        items: [...state.items, ...page.results],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<bool> approve(int id) => _decide(id, () => _repo.approveApproval(id));

  Future<bool> reject(int id, String reason) =>
      _decide(id, () => _repo.rejectApproval(id, reason: reason));

  Future<bool> _decide(int id, Future<void> Function() action) async {
    emit(state.copyWith(actioningId: id, message: null));
    try {
      await action();
      await _refresh();
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(message: e.message));
      return false;
    }
  }

  /// Re-pull page 1 in place (no loading flash) after a decision.
  Future<void> _refresh() async {
    _page = 1;
    try {
      final page = await _repo.fetchApprovals(page: 1);
      emit(state.copyWith(
        status: LoadStatus.success,
        items: page.results,
        hasMore: page.hasMore,
      ));
    } on ApiException {
      // Keep the current list; the decision still succeeded.
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/utils/month_filter.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/equipment_option.dart';
import 'package:sapbaq_admin/features/admin/data/models/mosque_need.dart';

/// The moderation queue of imam equipment requests. Regional managers
/// approve/reject (scoped to their governorate by the server); the dispatch
/// desk may only cancel. Defaults to the actionable `SUBMITTED` bucket in the
/// current month; the user can widen either filter.
class EquipmentRequestsState extends Equatable {
  final LoadStatus status;
  final List<AdminEquipmentRequest> items;
  final bool hasMore;
  final bool loadingMore;
  final int? actioningId;
  final String? message;

  /// `YYYY-MM`, or '' for all periods.
  final String month;

  /// A `status` value, or '' for any.
  final String statusFilter;

  const EquipmentRequestsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.actioningId,
    this.message,
    this.month = '',
    this.statusFilter = 'SUBMITTED',
  });

  EquipmentRequestsState copyWith({
    LoadStatus? status,
    List<AdminEquipmentRequest>? items,
    bool? hasMore,
    bool? loadingMore,
    int? actioningId,
    String? message,
    String? month,
    String? statusFilter,
  }) {
    return EquipmentRequestsState(
      status: status ?? this.status,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      actioningId: actioningId,
      message: message,
      month: month ?? this.month,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    hasMore,
    loadingMore,
    actioningId,
    message,
    month,
    statusFilter,
  ];
}

class EquipmentRequestsCubit extends Cubit<EquipmentRequestsState> {
  final AdminRepository _repo;
  EquipmentRequestsCubit(this._repo)
    : super(EquipmentRequestsState(month: currentMonthKey()));

  int _page = 1;

  Future<void> load() async {
    _page = 1;
    emit(
      state.copyWith(
        status: LoadStatus.loading,
        items: const [],
        loadingMore: false,
        message: null,
      ),
    );
    try {
      final page = await _repo.fetchEquipmentRequests(
        page: 1,
        status: state.statusFilter,
        month: state.month,
      );
      emit(
        state.copyWith(
          status: LoadStatus.success,
          items: page.results,
          hasMore: page.hasMore,
        ),
      );
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
      final page = await _repo.fetchEquipmentRequests(
        page: _page + 1,
        status: state.statusFilter,
        month: state.month,
      );
      _page += 1;
      emit(
        state.copyWith(
          items: [...state.items, ...page.results],
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException {
      emit(state.copyWith(loadingMore: false));
    }
  }

  void setMonth(String month) {
    if (month == state.month) return;
    emit(state.copyWith(month: month));
    load();
  }

  void setStatus(String value) {
    if (value == state.statusFilter) return;
    emit(state.copyWith(statusFilter: value));
    load();
  }

  /// Approving publishes the campaign, so it carries the chosen model — that
  /// choice is what freezes the funding goal.
  Future<bool> approve(int id, EquipmentPick pick) =>
      _act(id, () => _repo.approveEquipmentRequest(id, pick: pick));

  Future<bool> reject(int id, String reason) =>
      _act(id, () => _repo.rejectEquipmentRequest(id, reason: reason));

  Future<bool> cancel(int id) =>
      _act(id, () => _repo.cancelEquipmentRequest(id));

  Future<bool> _act(int id, Future<void> Function() action) async {
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

  /// Re-pull page 1 in place (no loading flash) after an action.
  Future<void> _refresh() async {
    _page = 1;
    try {
      final page = await _repo.fetchEquipmentRequests(
        page: 1,
        status: state.statusFilter,
        month: state.month,
      );
      emit(
        state.copyWith(
          status: LoadStatus.success,
          items: page.results,
          hasMore: page.hasMore,
        ),
      );
    } on ApiException {
      // Keep the current list; the action still succeeded.
    }
  }
}

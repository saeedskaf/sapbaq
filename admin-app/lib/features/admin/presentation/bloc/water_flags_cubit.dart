import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/utils/month_filter.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/mosque_need.dart';

/// The moderation queue of mosque water flags: approve (publish to donors) or
/// cancel. Handled by the dispatch desk and the regional manager (his
/// governorate, server-scoped). Defaults to the actionable `SUBMITTED` bucket
/// in the current month; the user can widen either filter.
class WaterFlagsState extends Equatable {
  final LoadStatus status;
  final List<AdminWaterFlag> items;
  final bool hasMore;
  final bool loadingMore;
  final int? actioningId;
  final String? message;

  /// `YYYY-MM`, or '' for all periods.
  final String month;

  /// A `status` value, or '' for any.
  final String statusFilter;

  const WaterFlagsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.actioningId,
    this.message,
    this.month = '',
    this.statusFilter = 'SUBMITTED',
  });

  WaterFlagsState copyWith({
    LoadStatus? status,
    List<AdminWaterFlag>? items,
    bool? hasMore,
    bool? loadingMore,
    int? actioningId,
    String? message,
    String? month,
    String? statusFilter,
  }) {
    return WaterFlagsState(
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

class WaterFlagsCubit extends Cubit<WaterFlagsState> {
  final AdminRepository _repo;
  WaterFlagsCubit(this._repo)
    : super(WaterFlagsState(month: currentMonthKey()));

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
      final page = await _repo.fetchWaterFlags(
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
      final page = await _repo.fetchWaterFlags(
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

  Future<bool> approve(int id) => _act(id, () => _repo.approveWaterFlag(id));

  Future<bool> cancel(int id) => _act(id, () => _repo.cancelWaterFlag(id));

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

  Future<void> _refresh() async {
    _page = 1;
    try {
      final page = await _repo.fetchWaterFlags(
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

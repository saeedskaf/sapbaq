import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/orders/data/models/activity.dart';
import 'package:sapbaq/features/orders/data/orders_repository.dart';

class ActivityState extends Equatable {
  final LoadStatus status;
  final List<ActivityRow> rows;
  final String? message;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  const ActivityState({
    this.status = LoadStatus.initial,
    this.rows = const [],
    this.message,
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
  });

  ActivityState copyWith({
    LoadStatus? status,
    List<ActivityRow>? rows,
    String? message,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) => ActivityState(
    status: status ?? this.status,
    rows: rows ?? this.rows,
    message: message,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );

  @override
  List<Object?> get props => [
    status,
    rows,
    message,
    page,
    hasMore,
    loadingMore,
  ];
}

/// Drives «طلباتي»: one paginated feed, no tabs and no filters.
///
/// The server owns the ordering (`ACTION_REQUIRED` first, then newest), so the
/// rows are appended exactly as they arrive — sorting them here would put a
/// paid order above the one still waiting to be paid.
class ActivityCubit extends Cubit<ActivityState> {
  final OrdersRepository _repo;

  ActivityCubit(this._repo) : super(const ActivityState());

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final page = await _repo.fetchActivity();
      emit(
        ActivityState(
          status: LoadStatus.success,
          rows: page.results,
          page: 1,
          hasMore: page.hasMore,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  /// Pull-to-refresh: reload the first page without tearing down what's on
  /// screen, so a refresh never flashes a spinner over a working list.
  Future<void> refresh() async {
    try {
      final page = await _repo.fetchActivity();
      emit(
        ActivityState(
          status: LoadStatus.success,
          rows: page.results,
          page: 1,
          hasMore: page.hasMore,
        ),
      );
    } on ApiException catch (e) {
      // Only surface an error when there's nothing already showing.
      if (state.rows.isEmpty) {
        emit(state.copyWith(status: LoadStatus.failure, message: e.message));
      }
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final next = await _repo.fetchActivity(page: state.page + 1);
      emit(
        state.copyWith(
          rows: [...state.rows, ...next.results],
          page: state.page + 1,
          hasMore: next.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException {
      // Keep the list as it is; the next scroll retries.
      emit(state.copyWith(loadingMore: false));
    }
  }
}

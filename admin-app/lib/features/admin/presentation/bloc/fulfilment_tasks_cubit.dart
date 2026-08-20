import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/location/location_service.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/fulfilment_task.dart';

/// The dispatch queue of marketplace fulfilment tasks (unified-dispatch doc
/// §1). Defaults to the open buckets (the server's default when no status is
/// sent); the user can narrow to a single status, including DONE for the
/// settled history. Every action refetches the list — an action usually moves
/// the task between buckets.
class FulfilmentTasksState extends Equatable {
  final LoadStatus status;
  final List<FulfilmentTask> items;
  final bool hasMore;
  final bool loadingMore;
  final int? actioningId;
  final String? message;

  /// A task `status` value, or '' for the server default (open tasks).
  final String statusFilter;

  /// True when the list came back sorted nearest-first.
  final bool sortedByDistance;

  const FulfilmentTasksState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.actioningId,
    this.message,
    this.statusFilter = '',
    this.sortedByDistance = false,
  });

  FulfilmentTasksState copyWith({
    LoadStatus? status,
    List<FulfilmentTask>? items,
    bool? hasMore,
    bool? loadingMore,
    int? actioningId,
    String? message,
    String? statusFilter,
    bool? sortedByDistance,
  }) {
    return FulfilmentTasksState(
      status: status ?? this.status,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      actioningId: actioningId,
      message: message,
      statusFilter: statusFilter ?? this.statusFilter,
      sortedByDistance: sortedByDistance ?? this.sortedByDistance,
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
    statusFilter,
    sortedByDistance,
  ];
}

class FulfilmentTasksCubit extends Cubit<FulfilmentTasksState> {
  final AdminRepository _repo;

  /// Null for roles that aren't asked for their location (office staff).
  final LocationService? _location;

  FulfilmentTasksCubit(this._repo, {LocationService? location})
    : _location = location,
      super(const FulfilmentTasksState());

  int _page = 1;

  /// Pinned for the whole list so paging can't reshuffle the server's order.
  LatLng? _origin;

  Future<void> load() async {
    _page = 1;
    _origin = await _location?.current();
    emit(
      state.copyWith(
        status: LoadStatus.loading,
        items: const [],
        loadingMore: false,
        message: null,
      ),
    );
    try {
      final page = await _repo.fetchFulfilmentTasks(
        page: 1,
        status: state.statusFilter,
        at: _origin,
      );
      emit(
        state.copyWith(
          status: LoadStatus.success,
          items: page.results,
          hasMore: page.hasMore,
          sortedByDistance: _origin != null,
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
      final page = await _repo.fetchFulfilmentTasks(
        page: _page + 1,
        status: state.statusFilter,
        at: _origin,
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

  void setStatus(String value) {
    if (value == state.statusFilter) return;
    emit(state.copyWith(statusFilter: value));
    load();
  }

  Future<bool> assignLeader(int id, int teamLeaderId) =>
      _action(id, () => _repo.assignTaskTeamLeader(id, teamLeaderId));

  Future<bool> assignHandler(int id, int handlerId) =>
      _action(id, () => _repo.assignTaskHandler(id, handlerId));

  Future<bool> fulfil(
    int id, {
    required String statement,
    required String photoPath,
  }) => _action(
    id,
    () => _repo.fulfilTask(id, statement: statement, photoPath: photoPath),
  );

  Future<bool> _action(int id, Future<FulfilmentTask> Function() run) async {
    emit(state.copyWith(actioningId: id, message: null));
    try {
      await run();
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
      final page = await _repo.fetchFulfilmentTasks(
        page: 1,
        status: state.statusFilter,
        at: _origin,
      );
      emit(
        state.copyWith(
          status: LoadStatus.success,
          items: page.results,
          hasMore: page.hasMore,
        ),
      );
    } on ApiException {
      // Keep the current list; the action itself already succeeded.
      emit(state.copyWith());
    }
  }
}

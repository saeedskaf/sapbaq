import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/location/location_service.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/core/utils/month_filter.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/maintenance_case.dart';

/// The maintenance queue. The server scopes visibility by role; on top of that
/// the user narrows by month (default: current), status and priority. Empty
/// filter strings mean "any" (the param is omitted).
class MaintenanceState extends Equatable {
  final LoadStatus status;
  final List<MaintenanceCase> items;
  final bool hasMore;
  final bool loadingMore;
  final String? message;

  /// `YYYY-MM`, or '' for all periods.
  final String month;

  /// A `status` value, or '' for any.
  final String statusFilter;

  /// A `priority` value, or '' for any.
  final String priorityFilter;

  /// An equipment-code search term, or '' for none.
  final String search;

  /// True when the list came back sorted nearest-first — i.e. the request
  /// carried the user's position (sorting doc §0).
  final bool sortedByDistance;

  const MaintenanceState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.message,
    this.month = '',
    this.statusFilter = '',
    this.priorityFilter = '',
    this.search = '',
    this.sortedByDistance = false,
  });

  MaintenanceState copyWith({
    LoadStatus? status,
    List<MaintenanceCase>? items,
    bool? hasMore,
    bool? loadingMore,
    String? message,
    String? month,
    String? statusFilter,
    String? priorityFilter,
    String? search,
    bool? sortedByDistance,
  }) {
    return MaintenanceState(
      status: status ?? this.status,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message,
      month: month ?? this.month,
      statusFilter: statusFilter ?? this.statusFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      search: search ?? this.search,
      sortedByDistance: sortedByDistance ?? this.sortedByDistance,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    hasMore,
    loadingMore,
    message,
    month,
    statusFilter,
    priorityFilter,
    search,
    sortedByDistance,
  ];
}

class MaintenanceCubit extends Cubit<MaintenanceState> {
  final AdminRepository _repo;

  /// Null for the roles that aren't asked for their location (office staff),
  /// which is also what makes the queue keep the server's default order.
  final LocationService? _location;

  MaintenanceCubit(this._repo, {LocationService? location})
    : _location = location,
      super(MaintenanceState(month: currentMonthKey()));

  int _page = 1;

  /// Pinned for the whole list: paging with a moved origin would reshuffle the
  /// server's ordering and duplicate or drop rows across pages.
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
      final page = await _repo.fetchMaintenanceCases(
        page: 1,
        status: state.statusFilter,
        priority: state.priorityFilter,
        month: state.month,
        search: state.search,
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
      final page = await _repo.fetchMaintenanceCases(
        page: _page + 1,
        status: state.statusFilter,
        priority: state.priorityFilter,
        month: state.month,
        search: state.search,
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

  void setPriority(String value) {
    if (value == state.priorityFilter) return;
    emit(state.copyWith(priorityFilter: value));
    load();
  }

  void setSearch(String value) {
    final trimmed = value.trim();
    if (trimmed == state.search) return;
    emit(state.copyWith(search: trimmed));
    load();
  }
}

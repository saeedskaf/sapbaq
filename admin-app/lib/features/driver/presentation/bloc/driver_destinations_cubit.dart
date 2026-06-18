import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/driver/data/driver_repository.dart';
import 'package:sapbaq_admin/features/driver/data/models/driver_destination.dart';

/// Driver deliveries tabs. New + Accepted both come from the ASSIGNED status
/// (split client-side by `accepted_at`); In-delivery comes from IN_DELIVERY;
/// Completed comes from DELIVERED (history).
enum DriverTab { newJobs, accepted, inDelivery, completed }

String _apiStatusFor(DriverTab tab) {
  switch (tab) {
    case DriverTab.inDelivery:
      return 'IN_DELIVERY';
    case DriverTab.completed:
      return 'DELIVERED';
    case DriverTab.newJobs:
    case DriverTab.accepted:
      return 'ASSIGNED';
  }
}

class DriverDestinationsState extends Equatable {
  final LoadStatus status;
  final List<DriverDestination> destinations; // raw, for the current api status
  final DriverTab tab;
  final bool hasMore;
  final bool loadingMore;
  final String? message;

  const DriverDestinationsState({
    this.status = LoadStatus.initial,
    this.destinations = const [],
    this.tab = DriverTab.newJobs,
    this.hasMore = false,
    this.loadingMore = false,
    this.message,
  });

  /// Destinations visible under the active tab (client-side split of ASSIGNED).
  List<DriverDestination> get visible {
    switch (tab) {
      case DriverTab.newJobs:
        return destinations.where((d) => d.isNew).toList();
      case DriverTab.accepted:
        return destinations.where((d) => d.canStartDelivery).toList();
      case DriverTab.inDelivery:
        return destinations.where((d) => d.isInDelivery).toList();
      case DriverTab.completed:
        return destinations.where((d) => d.isDelivered).toList();
    }
  }

  DriverDestinationsState copyWith({
    LoadStatus? status,
    List<DriverDestination>? destinations,
    DriverTab? tab,
    bool? hasMore,
    bool? loadingMore,
    String? message,
  }) {
    return DriverDestinationsState(
      status: status ?? this.status,
      destinations: destinations ?? this.destinations,
      tab: tab ?? this.tab,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message,
    );
  }

  @override
  List<Object?> get props =>
      [status, destinations, tab, hasMore, loadingMore, message];
}

class DriverDestinationsCubit extends Cubit<DriverDestinationsState> {
  final DriverRepository _repo;
  DriverDestinationsCubit(this._repo) : super(const DriverDestinationsState());

  int _page = 1;

  Future<void> load() => _loadFirstPage();

  Future<void> setTab(DriverTab tab) {
    if (tab == state.tab) return Future.value();
    // New ↔ Accepted share the ASSIGNED query — just re-filter, no refetch.
    if (_apiStatusFor(tab) == _apiStatusFor(state.tab)) {
      emit(state.copyWith(tab: tab));
      return Future.value();
    }
    emit(state.copyWith(tab: tab));
    return _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    _page = 1;
    emit(state.copyWith(
      status: LoadStatus.loading,
      destinations: const [],
      loadingMore: false,
      message: null,
    ));
    try {
      final page = await _repo.fetchDestinations(
        page: 1,
        status: _apiStatusFor(state.tab),
      );
      emit(state.copyWith(
        status: LoadStatus.success,
        destinations: page.results,
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
      final page = await _repo.fetchDestinations(
        page: _page + 1,
        status: _apiStatusFor(state.tab),
      );
      _page += 1;
      emit(state.copyWith(
        destinations: [...state.destinations, ...page.results],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      emit(state.copyWith(loadingMore: false));
    }
  }
}

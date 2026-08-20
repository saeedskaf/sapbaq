import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/catalog_order.dart';

/// The catalogue-order queue: customer purchases of a specific unit for a
/// mosque, awaiting a manager's approval and then installation
/// (FLUTTER_NONLIVE_EQUIPMENT_ORDERING §ثانياً). Every action refetches, since
/// an action usually moves the order to another bucket.
class CatalogOrdersState extends Equatable {
  final LoadStatus status;
  final List<CatalogOrder> items;
  final bool hasMore;
  final bool loadingMore;
  final int? actioningId;
  final String? message;

  /// A `status` value, or '' for the server default.
  final String statusFilter;

  const CatalogOrdersState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.actioningId,
    this.message,
    this.statusFilter = '',
  });

  CatalogOrdersState copyWith({
    LoadStatus? status,
    List<CatalogOrder>? items,
    bool? hasMore,
    bool? loadingMore,
    int? actioningId,
    String? message,
    String? statusFilter,
  }) {
    return CatalogOrdersState(
      status: status ?? this.status,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      actioningId: actioningId,
      message: message,
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
    statusFilter,
  ];
}

class CatalogOrdersCubit extends Cubit<CatalogOrdersState> {
  final AdminRepository _repo;
  CatalogOrdersCubit(this._repo) : super(const CatalogOrdersState());

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
      final page = await _repo.fetchCatalogOrders(
        page: 1,
        status: state.statusFilter,
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
      final page = await _repo.fetchCatalogOrders(
        page: _page + 1,
        status: state.statusFilter,
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

  Future<bool> approve(int id) =>
      _action(id, () => _repo.approveCatalogOrder(id));

  Future<bool> reject(int id, String reason) =>
      _action(id, () => _repo.rejectCatalogOrder(id, reason: reason));

  Future<bool> assignLeader(int id, int teamLeaderId) =>
      _action(id, () => _repo.assignCatalogTeamLeader(id, teamLeaderId));

  Future<bool> assignHandler(int id, int handlerId) =>
      _action(id, () => _repo.assignCatalogHandler(id, handlerId));

  Future<bool> install(int id) =>
      _action(id, () => _repo.installCatalogOrder(id));

  Future<bool> _action(int id, Future<CatalogOrder> Function() run) async {
    emit(state.copyWith(actioningId: id, message: null));
    try {
      await run();
      await load();
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(message: e.message));
      return false;
    }
  }
}

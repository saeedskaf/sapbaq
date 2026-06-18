import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';

/// Admin orders list tabs. [awaiting] (needs workshop assignment) is the default
/// working queue.
enum AdminOrdersTab { awaiting, all, delivered, cancelled }

class AdminOrdersState extends Equatable {
  final LoadStatus status;
  final List<AdminOrderSummary> orders;
  final AdminOrdersTab tab;
  final String search;
  final int total; // total matching orders (across all pages) for the active tab
  final bool hasMore;
  final bool loadingMore;
  final String? message;

  const AdminOrdersState({
    this.status = LoadStatus.initial,
    this.orders = const [],
    this.tab = AdminOrdersTab.awaiting,
    this.search = '',
    this.total = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.message,
  });

  AdminOrdersState copyWith({
    LoadStatus? status,
    List<AdminOrderSummary>? orders,
    AdminOrdersTab? tab,
    String? search,
    int? total,
    bool? hasMore,
    bool? loadingMore,
    String? message,
  }) {
    return AdminOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      tab: tab ?? this.tab,
      search: search ?? this.search,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message,
    );
  }

  @override
  List<Object?> get props =>
      [status, orders, tab, search, total, hasMore, loadingMore, message];
}

class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  final AdminRepository _repo;
  AdminOrdersCubit(this._repo) : super(const AdminOrdersState());

  int _page = 1;

  Future<void> load() => _loadFirstPage();

  Future<void> setTab(AdminOrdersTab tab) {
    if (tab == state.tab) return Future.value();
    emit(state.copyWith(tab: tab));
    return _loadFirstPage();
  }

  Future<void> search(String query) {
    final q = query.trim();
    if (q == state.search) return Future.value();
    emit(state.copyWith(search: q));
    return _loadFirstPage();
  }

  ({String? status, bool? awaiting}) _filterFor(AdminOrdersTab tab) {
    switch (tab) {
      case AdminOrdersTab.awaiting:
        return (status: null, awaiting: true);
      case AdminOrdersTab.all:
        return (status: null, awaiting: null);
      case AdminOrdersTab.delivered:
        return (status: 'DELIVERED', awaiting: null);
      case AdminOrdersTab.cancelled:
        return (status: 'CANCELLED', awaiting: null);
    }
  }

  Future<void> _loadFirstPage() async {
    _page = 1;
    emit(state.copyWith(
      status: LoadStatus.loading,
      orders: const [],
      loadingMore: false,
      message: null,
    ));
    final f = _filterFor(state.tab);
    try {
      final page = await _repo.fetchOrders(
        page: 1,
        status: f.status,
        awaitingAssignment: f.awaiting,
        search: state.search.isEmpty ? null : state.search,
      );
      emit(state.copyWith(
        status: LoadStatus.success,
        orders: page.results,
        total: page.count,
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
    final f = _filterFor(state.tab);
    try {
      final page = await _repo.fetchOrders(
        page: _page + 1,
        status: f.status,
        awaitingAssignment: f.awaiting,
        search: state.search.isEmpty ? null : state.search,
      );
      _page += 1;
      emit(state.copyWith(
        orders: [...state.orders, ...page.results],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      emit(state.copyWith(loadingMore: false));
    }
  }
}

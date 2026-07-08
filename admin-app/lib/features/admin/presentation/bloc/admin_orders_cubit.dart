import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order_counts.dart';

/// Admin orders list tabs. [awaiting] (needs workshop assignment) is the default
/// working queue. Declaration order is the display order — «الكل» stays last
/// (FLUTTER_TASKS item 9); [inProgress] maps to `?bucket=in_progress` (item 10).
enum AdminOrdersTab { awaiting, inProgress, delivered, cancelled, all }

class AdminOrdersState extends Equatable {
  final LoadStatus status;
  final List<AdminOrderSummary> orders;
  final AdminOrdersTab tab;
  final String search;
  final int total; // total matching orders (across all pages) for the active tab
  final bool hasMore;
  final bool loadingMore;

  /// Per-tab counts (§3). Null until the first counts fetch resolves; persists
  /// across tab switches (it doesn't depend on the active tab).
  final AdminOrderCounts? counts;
  final String? message;

  const AdminOrdersState({
    this.status = LoadStatus.initial,
    this.orders = const [],
    this.tab = AdminOrdersTab.awaiting,
    this.search = '',
    this.total = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.counts,
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
    AdminOrderCounts? counts,
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
      counts: counts ?? this.counts,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    orders,
    tab,
    search,
    total,
    hasMore,
    loadingMore,
    counts,
    message,
  ];
}

class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  final AdminRepository _repo;
  AdminOrdersCubit(this._repo) : super(const AdminOrdersState());

  int _page = 1;

  /// An "ORD-00001"-style query is an order-code lookup (`?code=`, FLUTTER_TASKS
  /// item 17); anything else goes through the generic `?search=`.
  static final _codePattern = RegExp(r'^ord-?\d+$', caseSensitive: false);

  ({String? search, String? code}) _searchParams() {
    final q = state.search;
    if (q.isEmpty) return (search: null, code: null);
    if (_codePattern.hasMatch(q)) return (search: null, code: q.toUpperCase());
    return (search: q, code: null);
  }

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

  ({String? status, bool? awaiting, String? bucket}) _filterFor(
    AdminOrdersTab tab,
  ) {
    switch (tab) {
      case AdminOrdersTab.awaiting:
        return (status: null, awaiting: true, bucket: null);
      case AdminOrdersTab.inProgress:
        return (status: null, awaiting: null, bucket: 'in_progress');
      case AdminOrdersTab.delivered:
        return (status: 'DELIVERED', awaiting: null, bucket: null);
      case AdminOrdersTab.cancelled:
        return (status: 'CANCELLED', awaiting: null, bucket: null);
      case AdminOrdersTab.all:
        return (status: null, awaiting: null, bucket: null);
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
      final q = _searchParams();
      final page = await _repo.fetchOrders(
        page: 1,
        status: f.status,
        awaitingAssignment: f.awaiting,
        bucket: f.bucket,
        search: q.search,
        code: q.code,
      );
      emit(state.copyWith(
        status: LoadStatus.success,
        orders: page.results,
        total: page.count,
        hasMore: page.hasMore,
      ));
      _refreshCounts();
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  /// Refresh the tab counts in the background. Counts are optional chrome, so a
  /// failure here is swallowed rather than failing the list.
  Future<void> _refreshCounts() async {
    try {
      final counts = await _repo.fetchCounts(search: _searchParams().search);
      if (!isClosed) emit(state.copyWith(counts: counts));
    } on ApiException {
      // ignore — keep the last known counts (or none).
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
      final q = _searchParams();
      final page = await _repo.fetchOrders(
        page: _page + 1,
        status: f.status,
        awaitingAssignment: f.awaiting,
        bucket: f.bucket,
        search: q.search,
        code: q.code,
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

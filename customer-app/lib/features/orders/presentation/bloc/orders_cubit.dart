import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/orders/data/models/order.dart';
import 'package:sapbaq/features/orders/data/orders_repository.dart';

class OrdersState extends Equatable {
  final LoadStatus status;
  final List<Order> orders;
  final bool hasMore;
  final bool loadingMore;
  final String? message;

  const OrdersState({
    this.status = LoadStatus.initial,
    this.orders = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.message,
  });

  OrdersState copyWith({
    LoadStatus? status,
    List<Order>? orders,
    bool? hasMore,
    bool? loadingMore,
    String? message,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, orders, hasMore, loadingMore, message];
}

/// The customer's full order history, paginated on scroll so **all** orders
/// (from day one) are reachable — no limit (per the customer-app spec).
class OrdersCubit extends Cubit<OrdersState> {
  final OrdersRepository _repo;
  OrdersCubit(this._repo) : super(const OrdersState());

  int _page = 1;

  Future<void> load() async {
    _page = 1;
    emit(state.copyWith(
      status: LoadStatus.loading,
      orders: const [],
      loadingMore: false,
      message: null,
    ));
    try {
      final page = await _repo.fetchOrders(page: 1);
      emit(state.copyWith(
        status: LoadStatus.success,
        orders: page.results,
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
      final page = await _repo.fetchOrders(page: _page + 1);
      _page += 1;
      emit(state.copyWith(
        orders: [...state.orders, ...page.results],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      // Keep what's loaded; a later scroll can retry.
      emit(state.copyWith(loadingMore: false));
    }
  }
}

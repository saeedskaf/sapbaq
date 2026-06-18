import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/orders/data/models/delivery_proof.dart';
import 'package:sapbaq/features/orders/data/models/order.dart';
import 'package:sapbaq/features/orders/data/models/review.dart';
import 'package:sapbaq/features/orders/data/orders_repository.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';

class OrderDetailState extends Equatable {
  final LoadStatus status;
  final Order? order;
  final Review? review;
  final List<DeliveryProof> proofs;
  final bool busy;
  final String? message;

  const OrderDetailState({
    this.status = LoadStatus.initial,
    this.order,
    this.review,
    this.proofs = const [],
    this.busy = false,
    this.message,
  });

  OrderDetailState copyWith({
    LoadStatus? status,
    Order? order,
    Review? review,
    List<DeliveryProof>? proofs,
    bool? busy,
    String? message,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      review: review ?? this.review,
      proofs: proofs ?? this.proofs,
      busy: busy ?? this.busy,
      message: message, // transient
    );
  }

  @override
  List<Object?> get props => [status, order, review, proofs, busy, message];
}

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrdersRepository _repo;
  final PaymentRepository _payment;
  int? _id;

  // While an order is still in progress, quietly re-fetch it so the status and
  // assigned driver stay live without the user pulling to refresh.
  Timer? _poll;
  static const Duration _pollInterval = Duration(seconds: 15);
  static const Set<String> _terminalStatuses = {'DELIVERED', 'CANCELLED'};

  OrderDetailCubit(this._repo, this._payment)
    : super(const OrderDetailState());

  Future<void> load(int id) async {
    _id = id;
    emit(const OrderDetailState(status: LoadStatus.loading));
    try {
      final order = await _repo.fetchOrder(id);
      final review =
          order.status == 'DELIVERED' ? await _repo.getReview(id) : null;
      final proofs = await _loadProofs(order);
      emit(
        OrderDetailState(
          status: LoadStatus.success,
          order: order,
          review: review,
          proofs: proofs,
        ),
      );
      _syncPolling(order.status);
    } on ApiException catch (e) {
      emit(OrderDetailState(status: LoadStatus.failure, message: e.message));
    }
  }

  /// Silent refresh (no spinner / no error toast) used by polling and the
  /// pull-to-refresh gesture. Keeps the last good data on a transient failure.
  Future<void> refresh() async {
    final id = _id;
    if (id == null) return;
    try {
      final order = await _repo.fetchOrder(id);
      final review =
          order.status == 'DELIVERED' ? await _repo.getReview(id) : null;
      final proofs = await _loadProofs(order);
      emit(
        state.copyWith(
          status: LoadStatus.success,
          order: order,
          review: review,
          proofs: proofs,
        ),
      );
      _syncPolling(order.status);
    } on ApiException {
      // Ignore — a dropped poll shouldn't disturb what's on screen.
    }
  }

  /// Drivers can attach proofs at any stage — the backend returns them even on
  /// CONFIRMED orders with PENDING destinations — so always fetch; the endpoint
  /// returns an empty list when there are none. Tolerate failure so a proofs
  /// hiccup never blocks the order from loading.
  Future<List<DeliveryProof>> _loadProofs(Order order) async {
    try {
      return await _repo.fetchProofs(order.id);
    } catch (_) {
      return const [];
    }
  }

  /// Start polling while the order is active; stop once it's terminal.
  void _syncPolling(String status) {
    if (_terminalStatuses.contains(status)) {
      _poll?.cancel();
      _poll = null;
      return;
    }
    _poll ??= Timer.periodic(_pollInterval, (_) => refresh());
  }

  Future<void> pay() => _action(() async {
    await _payment.payOrder(_id!);
    return _repo.fetchOrder(_id!);
  });

  Future<void> cancel({String? reason}) =>
      _action(() => _repo.cancelOrder(_id!, reason: reason));

  /// Runs an order-mutating action and refreshes [order] on success.
  Future<void> _action(Future<Order> Function() run) async {
    if (_id == null) return;
    emit(state.copyWith(busy: true));
    try {
      final order = await run();
      emit(
        state.copyWith(status: LoadStatus.success, order: order, busy: false),
      );
      _syncPolling(order.status);
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, message: e.message));
    }
  }

  Future<bool> submitReview({required int rating, String? comment}) async {
    if (_id == null) return false;
    emit(state.copyWith(busy: true));
    try {
      final review = await _repo.submitReview(
        _id!,
        rating: rating,
        comment: comment,
      );
      emit(state.copyWith(busy: false, review: review));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, message: e.message));
      return false;
    }
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}

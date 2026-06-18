import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';

class AdminOrderDetailState extends Equatable {
  final LoadStatus status;
  final AdminOrderDetail? order;
  final bool cancelling;
  final String? message;

  const AdminOrderDetailState({
    this.status = LoadStatus.initial,
    this.order,
    this.cancelling = false,
    this.message,
  });

  AdminOrderDetailState copyWith({
    LoadStatus? status,
    AdminOrderDetail? order,
    bool? cancelling,
    String? message,
  }) {
    return AdminOrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      cancelling: cancelling ?? this.cancelling,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, order, cancelling, message];
}

class AdminOrderDetailCubit extends Cubit<AdminOrderDetailState> {
  final AdminRepository _repo;
  final int orderId;

  AdminOrderDetailCubit(this._repo, this.orderId)
      : super(const AdminOrderDetailState());

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, message: null));
    try {
      final order = await _repo.fetchOrder(orderId);
      emit(state.copyWith(status: LoadStatus.success, order: order));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  /// Cancel the order. Returns true on success so the screen can surface a
  /// confirmation / pop.
  Future<bool> cancel(String reason) async {
    emit(state.copyWith(cancelling: true, message: null));
    try {
      final order = await _repo.cancel(orderId, reason: reason);
      emit(state.copyWith(cancelling: false, order: order));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(cancelling: false, message: e.message));
      return false;
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
import 'package:sapbaq_admin/features/admin/data/models/workshop.dart';

class AdminOrderDetailState extends Equatable {
  final LoadStatus status;
  final AdminOrderDetail? order;
  final bool cancelling;
  final bool assigning;
  final bool reassigning;
  final String? message;

  const AdminOrderDetailState({
    this.status = LoadStatus.initial,
    this.order,
    this.cancelling = false,
    this.assigning = false,
    this.reassigning = false,
    this.message,
  });

  AdminOrderDetailState copyWith({
    LoadStatus? status,
    AdminOrderDetail? order,
    bool? cancelling,
    bool? assigning,
    bool? reassigning,
    String? message,
  }) {
    return AdminOrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      cancelling: cancelling ?? this.cancelling,
      assigning: assigning ?? this.assigning,
      reassigning: reassigning ?? this.reassigning,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    order,
    cancelling,
    assigning,
    reassigning,
    message,
  ];
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

  /// Workshops for the reassign / distribute / complete picker. Returns null
  /// (and surfaces a message) on failure so the caller can abort the flow.
  Future<List<Workshop>?> fetchWorkshops() async {
    try {
      return await _repo.fetchWorkshops();
    } on ApiException catch (e) {
      emit(state.copyWith(message: e.message));
      return null;
    }
  }

  /// Team leaders for the manager's "assign to team leader" picker (T3).
  Future<List<Workshop>?> fetchTeamLeaders() async {
    try {
      return await _repo.fetchTeamLeaders();
    } on ApiException catch (e) {
      emit(state.copyWith(message: e.message));
      return null;
    }
  }

  /// Assign the whole order to a team leader (T3). Returns true on success; the
  /// refreshed order from the response replaces the current one.
  Future<bool> assignTeam(int teamLeaderId) async {
    emit(state.copyWith(assigning: true, message: null));
    try {
      final order = await _repo.assignTeam(orderId, teamLeaderId: teamLeaderId);
      emit(state.copyWith(assigning: false, order: order));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(assigning: false, message: e.message));
      return false;
    }
  }

  /// Team leader distributes one destination to a handler (T3).
  Future<bool> assignHandler(
    int destinationId,
    int driverId, {
    int? mosqueId,
  }) async {
    emit(state.copyWith(reassigning: true, message: null));
    try {
      final order = await _repo.assignHandler(
        orderId,
        destinationId: destinationId,
        driverId: driverId,
        mosqueId: mosqueId,
      );
      emit(state.copyWith(reassigning: false, order: order));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(reassigning: false, message: e.message));
      return false;
    }
  }

  /// Team leader approves a destination's completion directly (T3).
  Future<bool> completeDestination(
    int destinationId,
    int driverId, {
    int? mosqueId,
  }) async {
    emit(state.copyWith(reassigning: true, message: null));
    try {
      final order = await _repo.completeDestination(
        orderId,
        destinationId: destinationId,
        driverId: driverId,
        mosqueId: mosqueId,
      );
      emit(state.copyWith(reassigning: false, order: order));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(reassigning: false, message: e.message));
      return false;
    }
  }

  /// Move one destination to another workshop (§5). Returns true on success;
  /// the refreshed order (from the response) replaces the current one.
  Future<bool> reassign(int destinationId, int driverId) async {
    emit(state.copyWith(reassigning: true, message: null));
    try {
      final order = await _repo.reassign(
        orderId,
        destinationId: destinationId,
        driverId: driverId,
      );
      emit(state.copyWith(reassigning: false, order: order));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(reassigning: false, message: e.message));
      return false;
    }
  }

  /// Raise an escalation about this order (§9) to the user's direct manager.
  Future<bool> raiseEscalation(String reason) async {
    emit(state.copyWith(message: null));
    try {
      await _repo.raiseEscalation(reason: reason, orderId: orderId);
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(message: e.message));
      return false;
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

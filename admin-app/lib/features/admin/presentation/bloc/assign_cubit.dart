import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
import 'package:sapbaq_admin/features/admin/data/models/workshop.dart';

/// The admin's in-progress choice for one destination: which workshop, and
/// (for a MOST_NEEDED destination) which mosque.
class DestinationChoice extends Equatable {
  final int? driverId;
  final int? mosqueId;
  final String? mosqueName;

  const DestinationChoice({this.driverId, this.mosqueId, this.mosqueName});

  DestinationChoice copyWith({
    int? driverId,
    int? mosqueId,
    String? mosqueName,
  }) {
    return DestinationChoice(
      driverId: driverId ?? this.driverId,
      mosqueId: mosqueId ?? this.mosqueId,
      mosqueName: mosqueName ?? this.mosqueName,
    );
  }

  @override
  List<Object?> get props => [driverId, mosqueId, mosqueName];
}

class AssignState extends Equatable {
  final LoadStatus status;
  final List<AdminDestination> destinations; // pending destinations to assign
  final List<Workshop> workshops;
  final Map<int, DestinationChoice> choices; // destinationId → choice
  final bool submitting;
  final String? message;

  const AssignState({
    this.status = LoadStatus.initial,
    this.destinations = const [],
    this.workshops = const [],
    this.choices = const {},
    this.submitting = false,
    this.message,
  });

  AssignState copyWith({
    LoadStatus? status,
    List<AdminDestination>? destinations,
    List<Workshop>? workshops,
    Map<int, DestinationChoice>? choices,
    bool? submitting,
    String? message,
  }) {
    return AssignState(
      status: status ?? this.status,
      destinations: destinations ?? this.destinations,
      workshops: workshops ?? this.workshops,
      choices: choices ?? this.choices,
      submitting: submitting ?? this.submitting,
      message: message,
    );
  }

  @override
  List<Object?> get props =>
      [status, destinations, workshops, choices, submitting, message];
}

class AssignCubit extends Cubit<AssignState> {
  final AdminRepository _repo;
  final int orderId;

  AssignCubit(this._repo, this.orderId) : super(const AssignState());

  /// Loads the order's pending destinations and the available workshops.
  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, message: null));
    try {
      final order = await _repo.fetchOrder(orderId);
      final workshops = await _repo.fetchWorkshops();
      emit(state.copyWith(
        status: LoadStatus.success,
        destinations: order.pendingDestinations,
        workshops: workshops,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  void selectDriver(int destinationId, int driverId) {
    final next = Map<int, DestinationChoice>.from(state.choices);
    final current = next[destinationId] ?? const DestinationChoice();
    next[destinationId] = current.copyWith(driverId: driverId);
    emit(state.copyWith(choices: next));
  }

  void selectMosque(int destinationId, int mosqueId, String mosqueName) {
    final next = Map<int, DestinationChoice>.from(state.choices);
    final current = next[destinationId] ?? const DestinationChoice();
    next[destinationId] = current.copyWith(
      mosqueId: mosqueId,
      mosqueName: mosqueName,
    );
    emit(state.copyWith(choices: next));
  }

  /// Every destination must have a workshop, and every MOST_NEEDED destination
  /// without a mosque must have one chosen — matching the backend's all-or-none
  /// rule.
  bool get canSubmit {
    if (state.destinations.isEmpty) return false;
    for (final dest in state.destinations) {
      final choice = state.choices[dest.id];
      if (choice?.driverId == null) return false;
      if (dest.needsMosque && choice?.mosqueId == null) return false;
    }
    return true;
  }

  /// Submits the assignment. Returns the updated order on success, else null.
  Future<AdminOrderDetail?> submit() async {
    emit(state.copyWith(submitting: true, message: null));
    final assignments = state.destinations.map((dest) {
      final choice = state.choices[dest.id]!;
      return Assignment(
        destinationId: dest.id,
        driverId: choice.driverId!,
        mosqueId: dest.needsMosque ? choice.mosqueId : null,
      );
    }).toList();

    try {
      final order = await _repo.assign(orderId, assignments);
      emit(state.copyWith(submitting: false));
      return order;
    } on ApiException catch (e) {
      emit(state.copyWith(submitting: false, message: e.message));
      return null;
    }
  }
}

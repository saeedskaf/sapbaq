import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/driver/data/driver_repository.dart';
import 'package:sapbaq_admin/features/driver/data/models/driver_destination.dart';

class DriverDestinationDetailState extends Equatable {
  final LoadStatus status;
  final DriverDestination? destination;
  final bool acting; // accept / reject / start in flight
  final String? message;

  const DriverDestinationDetailState({
    this.status = LoadStatus.initial,
    this.destination,
    this.acting = false,
    this.message,
  });

  DriverDestinationDetailState copyWith({
    LoadStatus? status,
    DriverDestination? destination,
    bool? acting,
    String? message,
  }) {
    return DriverDestinationDetailState(
      status: status ?? this.status,
      destination: destination ?? this.destination,
      acting: acting ?? this.acting,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, destination, acting, message];
}

class DriverDestinationDetailCubit
    extends Cubit<DriverDestinationDetailState> {
  final DriverRepository _repo;
  final int destinationId;

  DriverDestinationDetailCubit(this._repo, this.destinationId)
      : super(const DriverDestinationDetailState());

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, message: null));
    try {
      final dest = await _repo.fetchDestination(destinationId);
      emit(state.copyWith(status: LoadStatus.success, destination: dest));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  Future<bool> accept() => _act(() => _repo.accept(destinationId));

  Future<bool> startDelivery() =>
      _act(() => _repo.startDelivery(destinationId));

  /// Reject the assignment. Returns true on success; the caller should pop,
  /// since a rejected destination leaves the driver's list.
  Future<bool> reject(String reason) async {
    emit(state.copyWith(acting: true, message: null));
    try {
      await _repo.reject(destinationId, reason: reason);
      emit(state.copyWith(acting: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(acting: false, message: e.message));
      return false;
    }
  }

  /// Runs an action then reloads the destination to reflect the new state.
  Future<bool> _act(Future<void> Function() action) async {
    emit(state.copyWith(acting: true, message: null));
    try {
      await action();
      final dest = await _repo.fetchDestination(destinationId);
      emit(state.copyWith(acting: false, destination: dest));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(acting: false, message: e.message));
      return false;
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/data/models/trusted_device.dart';

enum TrustedListStatus { loading, ready, error }

class TrustedDevicesState extends Equatable {
  final TrustedListStatus status;
  final List<TrustedDevice> devices;

  /// A revoke action is running.
  final bool busy;

  /// Localized error shown in the list body (list-load failure).
  final String? listError;

  /// One-shot toast for a revoke failure (reset on the next emit).
  final String? actionError;

  const TrustedDevicesState({
    this.status = TrustedListStatus.loading,
    this.devices = const [],
    this.busy = false,
    this.listError,
    this.actionError,
  });

  TrustedDevicesState copyWith({
    TrustedListStatus? status,
    List<TrustedDevice>? devices,
    bool? busy,
    String? listError,
    String? actionError,
  }) {
    return TrustedDevicesState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      busy: busy ?? this.busy,
      listError: listError ?? this.listError,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [status, devices, busy, listError, actionError];
}

/// Lists the user's trusted devices and revokes them.
class TrustedDevicesCubit extends Cubit<TrustedDevicesState> {
  final AuthRepository _repo;
  TrustedDevicesCubit(this._repo) : super(const TrustedDevicesState());

  Future<void> load() async {
    emit(state.copyWith(status: TrustedListStatus.loading, listError: null));
    try {
      final devices = await _repo.listTrustedDevices();
      emit(state.copyWith(status: TrustedListStatus.ready, devices: devices));
    } on ApiException catch (e) {
      emit(state.copyWith(status: TrustedListStatus.error, listError: e.message));
    }
  }

  Future<void> revoke(int id) async {
    emit(state.copyWith(busy: true));
    try {
      await _repo.revokeTrustedDevice(id);
      final devices = await _repo.listTrustedDevices();
      emit(state.copyWith(busy: false, devices: devices));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, actionError: e.message));
    }
  }
}

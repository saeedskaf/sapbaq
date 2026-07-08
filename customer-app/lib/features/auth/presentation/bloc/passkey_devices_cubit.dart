import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/auth/data/models/passkey_device.dart';
import 'package:sapbaq/features/auth/data/passkey_service.dart';

enum PasskeyListStatus { loading, ready, error }

class PasskeyDevicesState extends Equatable {
  final PasskeyListStatus status;
  final List<PasskeyDevice> devices;

  /// A register/delete action is running.
  final bool busy;

  /// Localized error to show in the list body (list-load failure).
  final String? listError;

  /// One-shot toast signals (reset on the next emit).
  final String? actionError; // localized (ApiException)
  final PasskeyFailure? actionFailure; // platform failure (UI maps)
  final bool registered; // a passkey was just added

  const PasskeyDevicesState({
    this.status = PasskeyListStatus.loading,
    this.devices = const [],
    this.busy = false,
    this.listError,
    this.actionError,
    this.actionFailure,
    this.registered = false,
  });

  PasskeyDevicesState copyWith({
    PasskeyListStatus? status,
    List<PasskeyDevice>? devices,
    bool? busy,
    String? listError,
    String? actionError,
    PasskeyFailure? actionFailure,
    bool registered = false,
  }) {
    return PasskeyDevicesState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      busy: busy ?? this.busy,
      listError: listError ?? this.listError,
      actionError: actionError,
      actionFailure: actionFailure,
      registered: registered,
    );
  }

  @override
  List<Object?> get props => [
    status,
    devices,
    busy,
    listError,
    actionError,
    actionFailure,
    registered,
  ];
}

/// Lists, adds, and removes the user's registered passkeys.
class PasskeyDevicesCubit extends Cubit<PasskeyDevicesState> {
  final AuthRepository _repo;
  PasskeyDevicesCubit(this._repo) : super(const PasskeyDevicesState());

  Future<void> load() async {
    emit(state.copyWith(status: PasskeyListStatus.loading, listError: null));
    try {
      final devices = await _repo.listPasskeys();
      emit(
        state.copyWith(status: PasskeyListStatus.ready, devices: devices),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: PasskeyListStatus.error, listError: e.message));
    }
  }

  Future<void> register({required String deviceName}) async {
    emit(state.copyWith(busy: true));
    try {
      final added = await _repo.registerPasskey(deviceName: deviceName);
      if (!added) {
        emit(state.copyWith(busy: false)); // cancelled
        return;
      }
      final devices = await _repo.listPasskeys();
      emit(state.copyWith(busy: false, devices: devices, registered: true));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, actionError: e.message));
    } on PasskeyException catch (e) {
      emit(state.copyWith(busy: false, actionFailure: e.reason));
    }
  }

  Future<void> delete(int id) async {
    emit(state.copyWith(busy: true));
    try {
      await _repo.deletePasskey(id);
      final devices = await _repo.listPasskeys();
      emit(state.copyWith(busy: false, devices: devices));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, actionError: e.message));
    }
  }
}

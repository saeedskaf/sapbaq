import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';

/// State for the map cubit (loads a `List<Mosque>`).
class MosquesState extends Equatable {
  final LoadStatus status;
  final List<Mosque> mosques;
  final String? message;

  const MosquesState({
    this.status = LoadStatus.initial,
    this.mosques = const [],
    this.message,
  });

  MosquesState copyWith({
    LoadStatus? status,
    List<Mosque>? mosques,
    String? message,
  }) {
    return MosquesState(
      status: status ?? this.status,
      mosques: mosques ?? this.mosques,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, mosques, message];
}

/// All mosques with coordinates (for the map tab).
class MosquesMapCubit extends Cubit<MosquesState> {
  final MosquesRepository _repo;
  MosquesMapCubit(this._repo) : super(const MosquesState());

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, message: null));
    try {
      final mosques = await _repo.fetchMosquesForMap();
      emit(state.copyWith(status: LoadStatus.success, mosques: mosques));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }
}

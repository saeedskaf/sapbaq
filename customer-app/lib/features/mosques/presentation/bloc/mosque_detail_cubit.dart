import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';

class MosqueDetailState extends Equatable {
  final LoadStatus status;
  final Mosque? mosque;
  final String? message;

  const MosqueDetailState({
    this.status = LoadStatus.initial,
    this.mosque,
    this.message,
  });

  @override
  List<Object?> get props => [status, mosque, message];
}

class MosqueDetailCubit extends Cubit<MosqueDetailState> {
  final MosquesRepository _repo;
  MosqueDetailCubit(this._repo) : super(const MosqueDetailState());

  Future<void> load(int id) async {
    emit(const MosqueDetailState(status: LoadStatus.loading));
    try {
      final mosque = await _repo.fetchMosque(id);
      emit(MosqueDetailState(status: LoadStatus.success, mosque: mosque));
    } on ApiException catch (e) {
      emit(MosqueDetailState(status: LoadStatus.failure, message: e.message));
    }
  }
}

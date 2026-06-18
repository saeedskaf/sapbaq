import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/addresses/data/addresses_repository.dart';
import 'package:sapbaq/features/addresses/data/models/address.dart';

class AddressesState extends Equatable {
  final LoadStatus status;
  final List<Address> items;
  final String? message;

  const AddressesState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.message,
  });

  @override
  List<Object?> get props => [status, items, message];
}

class AddressesCubit extends Cubit<AddressesState> {
  final AddressesRepository _repo;
  AddressesCubit(this._repo) : super(const AddressesState());

  Future<void> load() async {
    emit(const AddressesState(status: LoadStatus.loading));
    try {
      final items = await _repo.fetchAll();
      emit(AddressesState(status: LoadStatus.success, items: items));
    } on ApiException catch (e) {
      emit(AddressesState(status: LoadStatus.failure, message: e.message));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repo.delete(id);
      final items = state.items.where((a) => a.id != id).toList();
      emit(AddressesState(status: LoadStatus.success, items: items));
    } on ApiException catch (e) {
      emit(AddressesState(
        status: LoadStatus.success,
        items: state.items,
        message: e.message,
      ));
    }
  }
}

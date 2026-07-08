import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/customer_lookup.dart';

class CustomerLookupState extends Equatable {
  final LoadStatus status;
  final List<CustomerLookupResult> results;
  final String query;

  /// Whether [query] is a customer ID (`?id=`) rather than a phone/name.
  final bool byId;
  final String? message;

  const CustomerLookupState({
    this.status = LoadStatus.initial,
    this.results = const [],
    this.query = '',
    this.byId = false,
    this.message,
  });

  CustomerLookupState copyWith({
    LoadStatus? status,
    List<CustomerLookupResult>? results,
    String? query,
    bool? byId,
    String? message,
  }) {
    return CustomerLookupState(
      status: status ?? this.status,
      results: results ?? this.results,
      query: query ?? this.query,
      byId: byId ?? this.byId,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, results, query, byId, message];
}

class CustomerLookupCubit extends Cubit<CustomerLookupState> {
  final AdminRepository _repo;
  CustomerLookupCubit(this._repo) : super(const CustomerLookupState());

  // A query made of digits (optionally +, spaces, dashes) is treated as a
  // phone; anything else is treated as a name.
  static final _phonePattern = RegExp(r'^[+\d][\d\s\-]*$');

  Future<void> search(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) {
      emit(const CustomerLookupState());
      return;
    }
    emit(state.copyWith(
      status: LoadStatus.loading,
      query: query,
      byId: false,
      message: null,
    ));
    final isPhone = _phonePattern.hasMatch(query);
    try {
      final results = await _repo.lookupCustomers(
        phone: isPhone ? query : null,
        q: isPhone ? null : query,
      );
      emit(state.copyWith(status: LoadStatus.success, results: results));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  /// Lookup by the numeric customer ID (`?id=`, FLUTTER_TASKS item 3).
  Future<void> searchById(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) {
      emit(const CustomerLookupState());
      return;
    }
    final id = int.tryParse(query);
    emit(state.copyWith(
      status: LoadStatus.loading,
      query: query,
      byId: true,
      message: null,
    ));
    if (id == null) {
      emit(state.copyWith(status: LoadStatus.success, results: const []));
      return;
    }
    try {
      final results = await _repo.lookupCustomers(id: id);
      emit(state.copyWith(status: LoadStatus.success, results: results));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  /// Re-run the last search (used by the error view's retry).
  Future<void> retry() =>
      state.byId ? searchById(state.query) : search(state.query);
}

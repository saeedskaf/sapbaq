import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/escalation.dart';

class EscalationsState extends Equatable {
  final LoadStatus status;
  final List<Escalation> items;
  final bool hasMore;
  final bool loadingMore;

  /// The escalation currently being resolved (spinner). Always overwritten.
  final int? actioningId;
  final bool submitting; // raising a new escalation
  final String? message;

  const EscalationsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.actioningId,
    this.submitting = false,
    this.message,
  });

  EscalationsState copyWith({
    LoadStatus? status,
    List<Escalation>? items,
    bool? hasMore,
    bool? loadingMore,
    int? actioningId,
    bool? submitting,
    String? message,
  }) {
    return EscalationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      actioningId: actioningId,
      submitting: submitting ?? this.submitting,
      message: message,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, hasMore, loadingMore, actioningId, submitting, message];
}

class EscalationsCubit extends Cubit<EscalationsState> {
  final AdminRepository _repo;
  EscalationsCubit(this._repo) : super(const EscalationsState());

  int _page = 1;

  Future<void> load() async {
    _page = 1;
    emit(state.copyWith(
      status: LoadStatus.loading,
      items: const [],
      loadingMore: false,
      message: null,
    ));
    try {
      final page = await _repo.fetchEscalations(page: 1);
      emit(state.copyWith(
        status: LoadStatus.success,
        items: page.results,
        hasMore: page.hasMore,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore ||
        !state.hasMore ||
        state.status != LoadStatus.success) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repo.fetchEscalations(page: _page + 1);
      _page += 1;
      emit(state.copyWith(
        items: [...state.items, ...page.results],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<bool> resolve(int id) async {
    emit(state.copyWith(actioningId: id, message: null));
    try {
      await _repo.resolveEscalation(id);
      await _refresh();
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(message: e.message));
      return false;
    }
  }

  /// Raise a general escalation (no order) to the direct manager.
  Future<bool> raise(String reason) async {
    emit(state.copyWith(submitting: true, message: null));
    try {
      await _repo.raiseEscalation(reason: reason);
      await _refresh();
      emit(state.copyWith(submitting: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(submitting: false, message: e.message));
      return false;
    }
  }

  Future<void> _refresh() async {
    _page = 1;
    try {
      final page = await _repo.fetchEscalations(page: 1);
      emit(state.copyWith(
        status: LoadStatus.success,
        items: page.results,
        hasMore: page.hasMore,
      ));
    } on ApiException {
      // Keep the current list; the action still succeeded.
    }
  }
}

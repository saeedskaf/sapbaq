import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/activity_entry.dart';

class ActivityState extends Equatable {
  final LoadStatus status;
  final List<ActivityEntry> entries;
  final bool hasMore;
  final bool loadingMore;
  final String? message;

  const ActivityState({
    this.status = LoadStatus.initial,
    this.entries = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.message,
  });

  ActivityState copyWith({
    LoadStatus? status,
    List<ActivityEntry>? entries,
    bool? hasMore,
    bool? loadingMore,
    String? message,
  }) {
    return ActivityState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, entries, hasMore, loadingMore, message];
}

class ActivityCubit extends Cubit<ActivityState> {
  final AdminRepository _repo;
  ActivityCubit(this._repo) : super(const ActivityState());

  int _page = 1;

  Future<void> load() async {
    _page = 1;
    emit(state.copyWith(
      status: LoadStatus.loading,
      entries: const [],
      loadingMore: false,
      message: null,
    ));
    try {
      final page = await _repo.fetchActivity(page: 1);
      emit(state.copyWith(
        status: LoadStatus.success,
        entries: page.results,
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
      final page = await _repo.fetchActivity(page: _page + 1);
      _page += 1;
      emit(state.copyWith(
        entries: [...state.entries, ...page.results],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      emit(state.copyWith(loadingMore: false));
    }
  }
}

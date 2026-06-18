import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';

/// Shared state for both the list and map cubits (both load a `List<Mosque>`).
/// [hasMore]/[loadingMore] are used only by the paginated list.
class MosquesState extends Equatable {
  final LoadStatus status;
  final List<Mosque> mosques;
  final bool hasMore;
  final bool loadingMore;
  final String? message;

  const MosquesState({
    this.status = LoadStatus.initial,
    this.mosques = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.message,
  });

  MosquesState copyWith({
    LoadStatus? status,
    List<Mosque>? mosques,
    bool? hasMore,
    bool? loadingMore,
    String? message,
  }) {
    return MosquesState(
      status: status ?? this.status,
      mosques: mosques ?? this.mosques,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, mosques, hasMore, loadingMore, message];
}

/// Paginated mosque list (for the list tab) — accumulates pages on scroll.
class MosquesListCubit extends Cubit<MosquesState> {
  final MosquesRepository _repo;
  MosquesListCubit(this._repo) : super(const MosquesState());

  int _page = 1;
  String _search = '';
  String? _governorate;
  String? _area;
  String? _block;

  /// (Re)load from page 1 with the current query — used on first load, retry,
  /// and pull-to-refresh.
  Future<void> load() => _loadFirstPage();

  /// Apply a new search query (no-op if unchanged) and reload from page 1.
  Future<void> search(String query) {
    final q = query.trim();
    if (q == _search) return Future.value();
    _search = q;
    return _loadFirstPage();
  }

  /// Apply cascading governorate/area/block filters and reload from page 1.
  Future<void> applyFilters({String? governorate, String? area, String? block}) {
    _governorate = governorate;
    _area = area;
    _block = block;
    return _loadFirstPage();
  }

  String? get governorate => _governorate;
  String? get area => _area;
  String? get block => _block;
  bool get hasActiveFilters =>
      (_governorate?.isNotEmpty ?? false) ||
      (_area?.isNotEmpty ?? false) ||
      (_block?.isNotEmpty ?? false);

  Future<void> _loadFirstPage() async {
    _page = 1;
    emit(state.copyWith(
      status: LoadStatus.loading,
      mosques: const [],
      loadingMore: false,
      message: null,
    ));
    try {
      final page = await _repo.fetchMosques(
        page: 1,
        search: _query,
        governorate: _governorate,
        area: _area,
        block: _block,
      );
      emit(state.copyWith(
        status: LoadStatus.success,
        mosques: page.results,
        hasMore: page.hasMore,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  /// Append the next page (carrying the active query). No-ops while one is in
  /// flight, on the last page, or before the first page has loaded.
  Future<void> loadMore() async {
    if (state.loadingMore ||
        !state.hasMore ||
        state.status != LoadStatus.success) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repo.fetchMosques(
        page: _page + 1,
        search: _query,
        governorate: _governorate,
        area: _area,
        block: _block,
      );
      _page += 1;
      emit(state.copyWith(
        mosques: [...state.mosques, ...page.results],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      // Keep what's loaded; a later scroll can retry.
      emit(state.copyWith(loadingMore: false));
    }
  }

  String? get _query => _search.isEmpty ? null : _search;
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

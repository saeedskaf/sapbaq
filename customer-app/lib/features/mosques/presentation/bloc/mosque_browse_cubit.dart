import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/models/mosque_filters.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';

/// Which level of the mosque drill-down the list tab is showing.
enum MosqueBrowseStep { governorate, area, mosques }

/// State for the cascading mosque browser: pick a governorate, then an area,
/// then see that area's mosques. A non-empty [search] overrides the drill-down
/// and shows matching mosques from anywhere.
class MosqueBrowseState extends Equatable {
  final MosqueBrowseStep step;
  final LoadStatus status;

  /// Selected governorate (set once past the governorate step).
  final String? governorate;

  /// Selected area (set once on the mosques step).
  final String? area;

  /// Facet options for the current step (governorate or area lists).
  final List<FilterOption> options;

  /// Mosques for the mosques step, or the search results when [search] is set.
  final List<Mosque> mosques;

  final bool hasMore;
  final bool loadingMore;

  /// Active search query. When non-empty the UI shows [mosques] as results.
  final String search;

  final String? message;

  const MosqueBrowseState({
    this.step = MosqueBrowseStep.governorate,
    this.status = LoadStatus.initial,
    this.governorate,
    this.area,
    this.options = const [],
    this.mosques = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.search = '',
    this.message,
  });

  bool get isSearching => search.isNotEmpty;

  MosqueBrowseState copyWith({
    MosqueBrowseStep? step,
    LoadStatus? status,
    String? governorate,
    String? area,
    List<FilterOption>? options,
    List<Mosque>? mosques,
    bool? hasMore,
    bool? loadingMore,
    String? search,
    String? message,
  }) {
    return MosqueBrowseState(
      step: step ?? this.step,
      status: status ?? this.status,
      governorate: governorate ?? this.governorate,
      area: area ?? this.area,
      options: options ?? this.options,
      mosques: mosques ?? this.mosques,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      search: search ?? this.search,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
    step,
    status,
    governorate,
    area,
    options,
    mosques,
    hasMore,
    loadingMore,
    search,
    message,
  ];
}

/// Drives the mosque list tab as a governorate → area → mosques drill-down,
/// with a global search that short-circuits to matching mosques.
class MosqueBrowseCubit extends Cubit<MosqueBrowseState> {
  final MosquesRepository _repo;
  MosqueBrowseCubit(this._repo) : super(const MosqueBrowseState());

  int _page = 1;

  /// Each request claims a number; only the newest may emit. Without this a
  /// slow response for a level the user has already left lands on the level
  /// they moved to (e.g. one governorate's areas painting under another).
  int _seq = 0;

  /// First load — show the list of governorates.
  Future<void> start() => _loadGovernorates();

  /// Drill into a governorate to reveal its areas.
  Future<void> selectGovernorate(String governorate) {
    return _loadAreas(governorate);
  }

  /// Drill into an area to reveal its mosques.
  Future<void> selectArea(String area) {
    return _loadMosques(state.governorate, area);
  }

  /// Step back up one level (mosques → areas → governorates).
  Future<void> back() {
    switch (state.step) {
      case MosqueBrowseStep.mosques:
        return _loadAreas(state.governorate);
      case MosqueBrowseStep.area:
        return _loadGovernorates();
      case MosqueBrowseStep.governorate:
        return Future.value();
    }
  }

  /// Apply a search query. An empty query returns to the current drill level.
  Future<void> search(String query) {
    final q = query.trim();
    if (q == state.search) return Future.value();
    if (q.isEmpty) {
      emit(state.copyWith(search: ''));
      return _reloadCurrentStep();
    }
    final seq = ++_seq;
    _page = 1;
    emit(
      state.copyWith(
        search: q,
        status: LoadStatus.loading,
        mosques: const [],
        loadingMore: false,
        message: null,
      ),
    );
    return _fetchMosquePage(seq: seq, reset: true, search: q);
  }

  /// Retry whatever the current view is (search results or a drill level).
  Future<void> retry() {
    if (state.isSearching) {
      final seq = ++_seq;
      emit(state.copyWith(status: LoadStatus.loading, message: null));
      return _fetchMosquePage(seq: seq, reset: true, search: state.search);
    }
    return _reloadCurrentStep();
  }

  Future<void> _reloadCurrentStep() {
    switch (state.step) {
      case MosqueBrowseStep.governorate:
        return _loadGovernorates();
      case MosqueBrowseStep.area:
        return _loadAreas(state.governorate);
      case MosqueBrowseStep.mosques:
        return _loadMosques(state.governorate, state.area);
    }
  }

  Future<void> _loadGovernorates() async {
    final seq = ++_seq;
    emit(
      const MosqueBrowseState(
        step: MosqueBrowseStep.governorate,
        status: LoadStatus.loading,
      ),
    );
    try {
      final filters = await _repo.fetchFilters();
      if (seq != _seq) return;
      emit(
        state.copyWith(
          status: LoadStatus.success,
          options: filters.governorates,
        ),
      );
    } on ApiException catch (e) {
      if (seq != _seq) return;
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  Future<void> _loadAreas(String? governorate) async {
    final seq = ++_seq;
    emit(
      MosqueBrowseState(
        step: MosqueBrowseStep.area,
        status: LoadStatus.loading,
        governorate: governorate,
      ),
    );
    try {
      final filters = await _repo.fetchFilters(governorate: governorate);
      if (seq != _seq) return;
      emit(state.copyWith(status: LoadStatus.success, options: filters.areas));
    } on ApiException catch (e) {
      if (seq != _seq) return;
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  Future<void> _loadMosques(String? governorate, String? area) async {
    final seq = ++_seq;
    _page = 1;
    emit(
      MosqueBrowseState(
        step: MosqueBrowseStep.mosques,
        status: LoadStatus.loading,
        governorate: governorate,
        area: area,
      ),
    );
    await _fetchMosquePage(
      seq: seq,
      reset: true,
      governorate: governorate,
      area: area,
    );
  }

  /// Fetch page 1 (reset) or the next page of mosques for either the drilled
  /// area or the active search, and fold the result into state.
  Future<void> _fetchMosquePage({
    required int seq,
    required bool reset,
    String? search,
    String? governorate,
    String? area,
  }) async {
    try {
      final page = await _repo.fetchMosques(
        page: reset ? 1 : _page + 1,
        search: search,
        governorate: governorate,
        area: area,
      );
      if (seq != _seq) return;
      if (!reset) _page += 1;
      emit(
        state.copyWith(
          status: LoadStatus.success,
          mosques: reset ? page.results : [...state.mosques, ...page.results],
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException catch (e) {
      if (seq != _seq) return;
      if (reset) {
        emit(state.copyWith(status: LoadStatus.failure, message: e.message));
      } else {
        // Keep what's loaded; a later scroll can retry.
        emit(state.copyWith(loadingMore: false));
      }
    }
  }

  /// Append the next page of mosques (search results or the drilled area).
  Future<void> loadMore() async {
    final onMosques =
        state.isSearching || state.step == MosqueBrowseStep.mosques;
    if (!onMosques ||
        state.loadingMore ||
        !state.hasMore ||
        state.status != LoadStatus.success) {
      return;
    }
    final seq = ++_seq;
    emit(state.copyWith(loadingMore: true));
    await _fetchMosquePage(
      seq: seq,
      reset: false,
      search: state.isSearching ? state.search : null,
      governorate: state.isSearching ? null : state.governorate,
      area: state.isSearching ? null : state.area,
    );
  }
}

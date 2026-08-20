import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/mosques/data/mosque_lookup_repository.dart';

/// Which level of the drill-down is on screen.
enum MosqueBrowseStep { governorate, area, mosques }

/// State for the cascading mosque browser: pick a governorate, then an area,
/// then a mosque. A non-empty [search] overrides the drill-down and shows
/// matches from anywhere within the current scope.
///
/// Mirrors the customer app's browser step for step, so a mosque is chosen the
/// same way everywhere in the product.
class MosqueBrowseState extends Equatable {
  final MosqueBrowseStep step;
  final LoadStatus status;

  final String? governorate;
  final String? area;

  /// Facet rows for the current level (governorates or areas).
  final List<MosqueFacet> options;

  /// Mosques for the mosque level, or the matches while searching.
  final List<PickableMosque> mosques;

  final bool hasMore;
  final bool loadingMore;
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
    List<MosqueFacet>? options,
    List<PickableMosque>? mosques,
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

/// Drives the governorate → area → mosques walk, with a search that
/// short-circuits to matching mosques.
class MosqueBrowseCubit extends Cubit<MosqueBrowseState> {
  final MosqueLookupRepository _repo;

  /// When set, the browser never shows the governorate level and every query is
  /// confined to this governorate. That is how a regional manager's picker is
  /// scoped: he may only file for his own governorate, so offering him the
  /// others would only produce a 403 at submit time.
  final String? pinnedGovernorate;

  MosqueBrowseCubit(this._repo, {this.pinnedGovernorate})
    : _pin = pinnedGovernorate,
      super(const MosqueBrowseState());

  /// The pin actually in force. Dropped if the pinned governorate turns out to
  /// have no areas — the staff profile's governorate name and the mosque
  /// feed's are two separate strings, and a mismatch must not leave the picker
  /// in a dead end with nothing to choose. The server still enforces scope on
  /// submit, so falling back to the full list is safe.
  String? _pin;

  int _page = 1;

  /// Each request claims a number; only the newest may emit. Without this a
  /// slow response for a level the user has already left lands on the level
  /// they moved to.
  int _seq = 0;

  bool get _isPinned => _pin != null && _pin!.isNotEmpty;

  /// First load: the governorate list, or straight to a pinned governorate's
  /// areas.
  Future<void> start() => _isPinned ? _loadAreas(_pin) : _loadGovernorates();

  Future<void> selectGovernorate(String governorate) => _loadAreas(governorate);

  Future<void> selectArea(String area) => _loadMosques(state.governorate, area);

  /// Step back up one level. A pinned browser stops at its area list — there is
  /// no governorate level above it to return to.
  Future<void> back() {
    switch (state.step) {
      case MosqueBrowseStep.mosques:
        return _loadAreas(state.governorate);
      case MosqueBrowseStep.area:
        return _isPinned ? Future.value() : _loadGovernorates();
      case MosqueBrowseStep.governorate:
        return Future.value();
    }
  }

  /// True when [back] would actually go somewhere — drives the breadcrumb.
  bool get canGoBack =>
      state.step == MosqueBrowseStep.mosques ||
      (state.step == MosqueBrowseStep.area && !_isPinned);

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
    // A pinned browser searches inside its governorate, never outside it.
    return _fetchMosquePage(
      seq: seq,
      reset: true,
      search: q,
      governorate: _pin,
    );
  }

  Future<void> retry() {
    if (state.isSearching) {
      final seq = ++_seq;
      emit(state.copyWith(status: LoadStatus.loading, message: null));
      return _fetchMosquePage(
        seq: seq,
        reset: true,
        search: state.search,
        governorate: _pin,
      );
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
      final (governorates, _) = await _repo.filters();
      if (seq != _seq) return;
      emit(state.copyWith(status: LoadStatus.success, options: governorates));
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
      final (_, areas) = await _repo.filters(governorate: governorate);
      if (seq != _seq) return;
      // A pinned governorate that matches nothing is a name mismatch, not an
      // empty governorate — drop the pin and show the full list instead of a
      // browser the user can't get out of.
      if (areas.isEmpty && _isPinned && governorate == _pin) {
        _pin = null;
        await _loadGovernorates();
        return;
      }
      emit(state.copyWith(status: LoadStatus.success, options: areas));
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

  Future<void> _fetchMosquePage({
    required int seq,
    required bool reset,
    String? search,
    String? governorate,
    String? area,
  }) async {
    try {
      final page = await _repo.mosques(
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
      governorate: state.isSearching ? _pin : state.governorate,
      area: state.isSearching ? null : state.area,
    );
  }
}

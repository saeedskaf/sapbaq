import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/mosques_repository.dart';

/// App-wide favorite-mosques state. Holds the favorite list (for the favorites
/// screen) and the set of favorited ids (so a heart anywhere can reflect state
/// without a round-trip). Toggles are optimistic and revert on failure.
class FavoritesState extends Equatable {
  final LoadStatus status;
  final List<Mosque> mosques;
  final Set<int> ids;
  final String? message;

  const FavoritesState({
    this.status = LoadStatus.initial,
    this.mosques = const [],
    this.ids = const {},
    this.message,
  });

  @override
  List<Object?> get props => [status, mosques, ids, message];
}

class FavoritesCubit extends Cubit<FavoritesState> {
  final MosquesRepository _repo;
  FavoritesCubit(this._repo) : super(const FavoritesState());

  /// Clear on logout / for guests.
  void reset() => emit(const FavoritesState());

  Future<void> load() async {
    emit(const FavoritesState(status: LoadStatus.loading));
    try {
      final mosques = await _repo.fetchFavorites();
      emit(FavoritesState(
        status: LoadStatus.success,
        mosques: mosques,
        ids: mosques.map((m) => m.id).toSet(),
      ));
    } on ApiException catch (e) {
      emit(FavoritesState(status: LoadStatus.failure, message: e.message));
    }
  }

  Future<void> toggle(Mosque mosque) async {
    final id = mosque.id;
    final wasFavorite = state.ids.contains(id);
    final prevIds = state.ids;
    final prevMosques = state.mosques;

    final nextIds = Set<int>.from(prevIds);
    final nextMosques = List<Mosque>.from(prevMosques);
    if (wasFavorite) {
      nextIds.remove(id);
      nextMosques.removeWhere((m) => m.id == id);
    } else {
      nextIds.add(id);
      nextMosques.insert(0, mosque);
    }
    emit(FavoritesState(
      status: LoadStatus.success,
      mosques: nextMosques,
      ids: nextIds,
    ));

    try {
      if (wasFavorite) {
        await _repo.removeFavorite(id);
      } else {
        await _repo.addFavorite(id);
      }
    } on ApiException catch (e) {
      emit(FavoritesState(
        status: LoadStatus.success,
        mosques: prevMosques,
        ids: prevIds,
        message: e.message,
      ));
    }
  }
}

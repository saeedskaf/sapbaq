import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/features/banners/data/banners_repository.dart';
import 'package:sapbaq/features/banners/data/models/banner.dart';

class BannersState extends Equatable {
  final LoadStatus status;
  final List<PromoBanner> banners;

  const BannersState({
    this.status = LoadStatus.initial,
    this.banners = const [],
  });

  @override
  List<Object?> get props => [status, banners];
}

/// Loads home banners. They're non-critical decoration, so any failure resolves
/// to an empty list (the carousel just hides) rather than surfacing an error.
class BannersCubit extends Cubit<BannersState> {
  final BannersRepository _repo;
  BannersCubit(this._repo) : super(const BannersState());

  Future<void> load() async {
    if (isClosed) return;
    emit(const BannersState(status: LoadStatus.loading));
    try {
      final banners = await _repo.fetchBanners();
      if (isClosed) return;
      emit(BannersState(status: LoadStatus.success, banners: banners));
    } catch (_) {
      if (isClosed) return;
      emit(const BannersState(status: LoadStatus.failure));
    }
  }
}

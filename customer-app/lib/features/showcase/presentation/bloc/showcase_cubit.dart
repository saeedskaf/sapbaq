import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/showcase/data/models/showcase_section.dart';
import 'package:sapbaq/features/showcase/data/showcase_repository.dart';

class ShowcaseState extends Equatable {
  final LoadStatus status;
  final List<ShowcaseSection> sections;
  final String? message;

  const ShowcaseState({
    this.status = LoadStatus.initial,
    this.sections = const [],
    this.message,
  });

  bool get isEmpty => sections.every((s) => s.items.isEmpty);

  @override
  List<Object?> get props => [status, sections, message];
}

class ShowcaseCubit extends Cubit<ShowcaseState> {
  final ShowcaseRepository _repo;
  ShowcaseCubit(this._repo) : super(const ShowcaseState());

  Future<void> load() async {
    emit(const ShowcaseState(status: LoadStatus.loading));
    try {
      final sections = await _repo.fetchSections();
      emit(ShowcaseState(status: LoadStatus.success, sections: sections));
    } on ApiException catch (e) {
      emit(ShowcaseState(status: LoadStatus.failure, message: e.message));
    }
  }
}

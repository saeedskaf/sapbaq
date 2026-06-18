import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/info/data/content_repository.dart';
import 'package:sapbaq/features/info/data/models/content_page.dart';

class ContentState extends Equatable {
  final LoadStatus status;
  final ContentPage? page;
  final String? message;

  const ContentState({
    this.status = LoadStatus.initial,
    this.page,
    this.message,
  });

  @override
  List<Object?> get props => [status, page, message];
}

class ContentCubit extends Cubit<ContentState> {
  final ContentRepository _repo;
  final String slug;

  ContentCubit(this._repo, this.slug) : super(const ContentState());

  Future<void> load() async {
    emit(const ContentState(status: LoadStatus.loading));
    try {
      final page = await _repo.fetchContent(slug);
      emit(ContentState(status: LoadStatus.success, page: page));
    } on ApiException catch (e) {
      emit(ContentState(status: LoadStatus.failure, message: e.message));
    }
  }
}

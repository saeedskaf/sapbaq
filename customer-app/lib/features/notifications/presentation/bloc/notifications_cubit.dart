import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/notifications/data/models/app_notification.dart';
import 'package:sapbaq/features/notifications/data/notifications_repository.dart';

class NotificationsState extends Equatable {
  final LoadStatus status;
  final List<AppNotification> items;

  /// The next page to request; null once the last page has been loaded (T5).
  final int? nextPage;
  final bool loadingMore;
  final String? message;

  const NotificationsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.nextPage,
    this.loadingMore = false,
    this.message,
  });

  bool get hasMore => nextPage != null;

  NotificationsState copyWith({
    LoadStatus? status,
    List<AppNotification>? items,
    int? nextPage,
    bool clearNextPage = false,
    bool? loadingMore,
    String? message,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      nextPage: clearNextPage ? null : (nextPage ?? this.nextPage),
      loadingMore: loadingMore ?? this.loadingMore,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, items, nextPage, loadingMore, message];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repo;
  NotificationsCubit(this._repo) : super(const NotificationsState());

  /// Load (or reload) the first page.
  Future<void> load() async {
    emit(const NotificationsState(status: LoadStatus.loading));
    try {
      final page = await _repo.fetchNotifications(page: 1);
      emit(
        NotificationsState(
          status: LoadStatus.success,
          items: page.results,
          nextPage: page.hasMore ? 2 : null,
        ),
      );
    } on ApiException catch (e) {
      emit(NotificationsState(status: LoadStatus.failure, message: e.message));
    }
  }

  /// Append the next page (infinite scroll). No-op while already fetching or
  /// once the last page (`next == null`) has been reached.
  Future<void> loadMore() async {
    final page = state.nextPage;
    if (page == null || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true, message: null));
    try {
      final next = await _repo.fetchNotifications(page: page);
      emit(
        state.copyWith(
          items: [...state.items, ...next.results],
          loadingMore: false,
          nextPage: next.hasMore ? page + 1 : null,
          clearNextPage: !next.hasMore,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(loadingMore: false, message: e.message));
    }
  }
}

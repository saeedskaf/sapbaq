import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';
import 'package:sapbaq_admin/features/notifications/data/models/app_notification.dart';
import 'package:sapbaq_admin/features/notifications/data/notifications_repository.dart';

class NotificationsState extends Equatable {
  final LoadStatus status;
  final List<AppNotification> items;

  /// The next page to request; null once the last page has been loaded (T5).
  final int? nextPage;
  final bool loadingMore;
  final String? message;

  /// Box-wide unread total from the server (not just the loaded pages).
  final int unreadCount;

  const NotificationsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.nextPage,
    this.loadingMore = false,
    this.message,
    this.unreadCount = 0,
  });

  bool get hasMore => nextPage != null;

  NotificationsState copyWith({
    LoadStatus? status,
    List<AppNotification>? items,
    int? nextPage,
    bool clearNextPage = false,
    bool? loadingMore,
    String? message,
    int? unreadCount,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      nextPage: clearNextPage ? null : (nextPage ?? this.nextPage),
      loadingMore: loadingMore ?? this.loadingMore,
      message: message,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    nextPage,
    loadingMore,
    message,
    unreadCount,
  ];
}

class NotificationsCubit extends Cubit<NotificationsState>
    with WidgetsBindingObserver {
  final NotificationsRepository _repo;
  StreamSubscription<Map<String, dynamic>>? _pushSub;
  bool _resyncing = false;

  /// [pushData] is the foreground-push stream — a push arriving while the
  /// inbox is alive triggers a silent [resync] so the new row appears without
  /// a pull-to-refresh. The cubit also resyncs when the app returns to the
  /// foreground, covering pushes that arrived while it was backgrounded —
  /// this matters here more than anywhere: the inbox is a shell tab that
  /// stays alive for the whole session and never refetches on its own.
  NotificationsCubit(this._repo, {Stream<Map<String, dynamic>>? pushData})
    : super(const NotificationsState()) {
    _pushSub = pushData?.listen((_) => unawaited(resync()));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(resync());
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _pushSub?.cancel();
    return super.close();
  }

  /// Silently re-fetch page 1 and merge it on top of the loaded list — new
  /// rows appear, refreshed rows replace their loaded copies, and older pages
  /// (plus the scroll position) stay untouched. No-op before the first
  /// successful [load] (nothing to merge into, and the user may not be
  /// signed in yet).
  Future<void> resync() async {
    if (state.status != LoadStatus.success || _resyncing) return;
    _resyncing = true;
    try {
      final page = await _repo.fetchNotifications(page: 1);
      final pageIds = {for (final n in page.items) n.id};
      emit(
        state.copyWith(
          items: [
            ...page.items,
            ...state.items.where((n) => !pageIds.contains(n.id)),
          ],
          unreadCount: page.unreadCount,
        ),
      );
    } on ApiException {
      // Silent — the list simply stays as it was.
    } finally {
      _resyncing = false;
    }
  }

  /// Load (or reload) the first page.
  Future<void> load() async {
    emit(const NotificationsState(status: LoadStatus.loading));
    try {
      final page = await _repo.fetchNotifications(page: 1);
      emit(
        NotificationsState(
          status: LoadStatus.success,
          items: page.items,
          nextPage: page.hasMore ? 2 : null,
          unreadCount: page.unreadCount,
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
      // New arrivals shift the server's page offsets, so a later page can
      // resend rows we already hold — drop them instead of duplicating.
      final known = {for (final n in state.items) n.id};
      emit(
        state.copyWith(
          items: [
            ...state.items,
            ...next.items.where((n) => !known.contains(n.id)),
          ],
          loadingMore: false,
          nextPage: next.hasMore ? page + 1 : null,
          clearNextPage: !next.hasMore,
          unreadCount: next.unreadCount,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(loadingMore: false, message: e.message));
    }
  }

  /// Mark one row read (optimistic), then reconcile the count with the server.
  /// Safe to call on an already-read row — the server is idempotent.
  Future<void> markRead(int id) async {
    final target = state.items.where((n) => n.id == id).firstOrNull;
    if (target == null || target.read) return;
    emit(
      state.copyWith(
        items: [
          for (final n in state.items)
            if (n.id == id) n.asRead() else n,
        ],
        unreadCount: (state.unreadCount - 1).clamp(0, 1 << 30),
      ),
    );
    try {
      final unread = await _repo.markRead(id);
      emit(state.copyWith(unreadCount: unread));
    } on ApiException {
      // Keep the optimistic state; the tap still navigated.
    }
  }

  /// Mark every row read.
  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;
    emit(
      state.copyWith(
        items: [for (final n in state.items) n.asRead()],
        unreadCount: 0,
      ),
    );
    try {
      final unread = await _repo.markAllRead();
      emit(state.copyWith(unreadCount: unread));
    } on ApiException {
      // Keep the optimistic state.
    }
  }
}

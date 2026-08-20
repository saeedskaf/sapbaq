import 'dart:async';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/features/notifications/data/notifications_repository.dart';

/// The standing unread-notifications count behind the nav bar's bell badge —
/// app-wide, so it's visible from every tab (backend reply §1).
///
/// Kept fresh from three sources: an explicit [refresh] (app start / tab
/// visits), the inbox propagating the server count after it marks rows read
/// ([setCount]), and foreground pushes carrying `data.unread_count` for a live
/// bump without a request. Never surfaces an error — a badge that lies low
/// beats one that throws.
///
/// Every count also mirrors onto the OS app-icon badge (iOS; supported Android
/// launchers), so reading in-app clears the icon the backend set via
/// `aps.badge` on arrival.
class NotificationsBadgeCubit extends Cubit<int> {
  final NotificationsRepository _repo;
  StreamSubscription<Map<String, dynamic>>? _sub;

  NotificationsBadgeCubit(this._repo, {Stream<Map<String, dynamic>>? pushData})
    : super(0) {
    _sub = pushData?.listen(_onPush);
  }

  @override
  void emit(int state) {
    super.emit(state);
    unawaited(_syncOsBadge(state));
  }

  Future<void> _syncOsBadge(int count) async {
    try {
      await AppBadgePlus.updateBadge(count);
    } catch (_) {
      // The icon badge is cosmetic; never let it disturb app state.
    }
  }

  void _onPush(Map<String, dynamic> data) {
    final raw = data['unread_count'];
    final value = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    if (value != null) emit(value < 0 ? 0 : value);
  }

  /// Pull the current unread total. Safe to call often; swallows failures.
  Future<void> refresh() async {
    try {
      emit(await _repo.fetchUnreadCount());
    } catch (_) {
      // Leave the last known count.
    }
  }

  /// Adopt a count the inbox already learned from the server.
  void setCount(int value) => emit(value < 0 ? 0 : value);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

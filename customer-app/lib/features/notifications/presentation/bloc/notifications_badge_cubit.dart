import 'dart:async';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/features/notifications/data/notifications_repository.dart';

/// The standing unread-notifications count behind the home bell badge —
/// app-wide, visible from every tab (backend reply §1). Loaded on sign-in,
/// refreshed after the inbox loads / marks rows read, and bumped live from a
/// foreground push's `data.unread_count`. Never surfaces an error.
///
/// Every count also mirrors onto the OS app-icon badge (iOS; supported Android
/// launchers), so reading in-app clears the icon the backend set via
/// `aps.badge` on arrival.
class NotificationsBadgeCubit extends Cubit<int> {
  final NotificationsRepository _repo;
  NotificationsBadgeCubit(this._repo) : super(0);

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

  /// Pull the current unread total. Safe to call often; swallows failures.
  Future<void> refresh() async {
    try {
      emit(await _repo.fetchUnreadCount());
    } catch (_) {
      // Leave the last known count.
    }
  }

  /// Alias for clarity at call sites that load on sign-in.
  Future<void> load() => refresh();

  /// Adopt a count already known (the inbox after a mark, or a push payload).
  void setCount(int value) => emit(value < 0 ? 0 : value);

  void reset() => emit(0);
}

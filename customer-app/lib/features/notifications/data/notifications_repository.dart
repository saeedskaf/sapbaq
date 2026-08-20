import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/pagination.dart';
import 'package:sapbaq/features/notifications/data/models/app_notification.dart';
import 'package:sapbaq/features/notifications/data/models/notification_preferences.dart';

/// One page of the inbox plus the box-wide unread total (`unread_count` in the
/// page envelope, returned with every page — backend reply §1).
class NotificationsPage {
  final List<AppNotification> items;
  final bool hasMore;
  final int unreadCount;
  const NotificationsPage({
    required this.items,
    required this.hasMore,
    required this.unreadCount,
  });
}

class NotificationsRepository {
  final Dio _dio;
  NotificationsRepository(this._dio);

  /// Register this device's FCM token so the backend can target it with pushes.
  /// Call once a token has been obtained (see `PushNotificationService`).
  ///
  /// [language] (`ar`/`en`) is the user's preferred push language: the backend
  /// stores it and localizes background pushes (sent from a queue, with no
  /// `Accept-Language` header). Re-send with the same token to update it when
  /// the user switches the app language.
  Future<void> registerDevice({
    required String token,
    String platform = 'android',
    String? language,
  }) {
    return guardApi(
      () => _dio.post(
        ApiEndpoints.devices,
        data: {
          'token': token,
          'platform': platform,
          if (language != null && language.isNotEmpty) 'language': language,
        },
      ),
    );
  }

  /// Remove this device's token (e.g. on logout) so it stops receiving pushes.
  Future<void> unregisterDevice(String token) {
    return guardApi(() => _dio.delete(ApiEndpoints.device(token)));
  }

  /// One page of the user's notification inbox (newest first, server-ordered),
  /// with the box-wide `unread_count` from the envelope (T5).
  Future<NotificationsPage> fetchNotifications({int page = 1}) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page},
      );
      final map = Map<String, dynamic>.from(res.data as Map);
      final parsed = PaginatedResponse.fromJson(map, AppNotification.fromJson);
      return NotificationsPage(
        items: parsed.results,
        hasMore: parsed.hasMore,
        unreadCount: map['unread_count'] as int? ?? 0,
      );
    });
  }

  /// Mark one row read → returns the new box-wide unread count. Idempotent on
  /// the server (already-read / missing / not-yours all return 200).
  Future<int> markRead(int id) {
    return guardApi(() async {
      final res = await _dio.post(ApiEndpoints.notificationRead(id));
      return _unreadOf(res.data);
    });
  }

  /// Mark every row of the current user read → returns 0 (the new count).
  Future<int> markAllRead() {
    return guardApi(() async {
      final res = await _dio.post(ApiEndpoints.notificationsReadAll);
      return _unreadOf(res.data);
    });
  }

  /// The box-wide unread count on its own (for the standing nav badge).
  Future<int> fetchUnreadCount() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.notificationsUnreadCount);
      return _unreadOf(res.data);
    });
  }

  int _unreadOf(dynamic data) =>
      data is Map ? (data['unread_count'] as int? ?? 0) : 0;

  /// The user's notification opt-ins.
  Future<NotificationPreferences> fetchPreferences() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.notificationPreferences);
      return NotificationPreferences.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// Partially update the opt-ins (send only the changed categories).
  Future<NotificationPreferences> updatePreferences(Map<String, bool> changes) {
    return guardApi(() async {
      final res = await _dio.patch(
        ApiEndpoints.notificationPreferences,
        data: changes,
      );
      return NotificationPreferences.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }
}

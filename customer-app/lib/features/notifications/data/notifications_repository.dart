import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/pagination.dart';
import 'package:sapbaq/features/notifications/data/models/app_notification.dart';
import 'package:sapbaq/features/notifications/data/models/notification_preferences.dart';

class NotificationsRepository {
  final Dio _dio;
  NotificationsRepository(this._dio);

  /// Register this device's FCM token so the backend can target it with pushes.
  /// Call once a token has been obtained (see `PushNotificationService`).
  Future<void> registerDevice({
    required String token,
    String platform = 'android',
  }) {
    return guardApi(
      () => _dio.post(
        ApiEndpoints.devices,
        data: {'token': token, 'platform': platform},
      ),
    );
  }

  /// Remove this device's token (e.g. on logout) so it stops receiving pushes.
  Future<void> unregisterDevice(String token) {
    return guardApi(() => _dio.delete(ApiEndpoints.device(token)));
  }

  /// One page of the user's notification inbox (newest first, server-ordered).
  /// Returns the full paginated envelope so callers can page through it (T5).
  Future<PaginatedResponse<AppNotification>> fetchNotifications({
    int page = 1,
  }) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page},
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        AppNotification.fromJson,
      );
    });
  }

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

import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/pagination.dart';
import 'package:sapbaq/features/notifications/data/models/app_notification.dart';
import 'package:sapbaq/features/notifications/data/models/notification_preferences.dart';

class NotificationsRepository {
  final Dio _dio;
  NotificationsRepository(this._dio);

  /// The user's notification inbox (newest first, paginated by the backend).
  Future<List<AppNotification>> fetchNotifications() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.notifications);
      final page = PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        AppNotification.fromJson,
      );
      return page.results;
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

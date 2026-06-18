import 'package:dio/dio.dart';
import 'package:sapbaq_admin/core/network/api_endpoints.dart';
import 'package:sapbaq_admin/core/network/api_guard.dart';
import 'package:sapbaq_admin/core/network/pagination.dart';
import 'package:sapbaq_admin/features/notifications/data/models/app_notification.dart';

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

  /// Register this device's FCM token for push notifications. Call once the
  /// app has obtained a token (FCM wiring is added with the messaging setup).
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
}

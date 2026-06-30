import 'package:dio/dio.dart';
import 'package:sapbaq_admin/core/network/api_endpoints.dart';
import 'package:sapbaq_admin/core/network/api_guard.dart';
import 'package:sapbaq_admin/core/network/pagination.dart';
import 'package:sapbaq_admin/features/notifications/data/models/app_notification.dart';

class NotificationsRepository {
  final Dio _dio;
  NotificationsRepository(this._dio);

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

  /// Remove this device's token (e.g. on logout) so it stops receiving pushes.
  Future<void> unregisterDevice(String token) {
    return guardApi(() => _dio.delete(ApiEndpoints.device(token)));
  }
}

import 'package:sapbaq/app/router/app_routes.dart';

/// A resolved deep-link target for a tapped notification.
class NotificationRoute {
  final String name;
  final Map<String, String> pathParameters;
  const NotificationRoute(this.name, [this.pathParameters = const {}]);
}

/// Maps a customer notification's type + ids to the screen it should open.
/// Mirrors the in-app inbox tap behaviour (see `notifications_screen.dart`): a
/// support notification opens its ticket, an order-scoped one opens that order;
/// anything else falls back to the notifications inbox so the tap always lands
/// somewhere relevant.
NotificationRoute? resolveNotificationRoute(
  String type, {
  int? orderId,
  int? ticketId,
}) {
  if (ticketId != null) {
    return NotificationRoute(AppRoutes.ticketDetailName, {'id': '$ticketId'});
  }
  if (type.startsWith('support.')) {
    return const NotificationRoute(AppRoutes.supportName);
  }
  if (orderId != null) {
    return NotificationRoute(AppRoutes.orderDetailName, {'id': '$orderId'});
  }
  return const NotificationRoute(AppRoutes.notificationsName);
}

/// Pulls an int id out of an FCM `data` map (values arrive as strings).
int? notificationDataInt(Map<String, dynamic> data, String key) {
  final raw = data[key];
  if (raw is int) return raw;
  return int.tryParse(raw?.toString() ?? '');
}

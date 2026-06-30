import 'package:sapbaq_admin/app/router/app_routes.dart';

/// A resolved deep-link target for a tapped notification.
class NotificationRoute {
  final String name;
  final Map<String, String> pathParameters;
  const NotificationRoute(this.name, [this.pathParameters = const {}]);
}

/// Maps a staff notification's type + ids to the screen it should open (§14).
/// Returns null when there's nothing specific to open. Used by both the in-app
/// inbox and a tapped system push, so they behave identically.
///
/// Role mismatches (e.g. a service handler reaching an `/admin/*` route) are
/// caught by the router's redirect, which sends them back to their shell.
NotificationRoute? resolveNotificationRoute(
  String type, {
  int? orderId,
  int? destinationId,
  int? approvalId,
  int? escalationId,
}) {
  if (type.startsWith('pending_approval') || approvalId != null) {
    return const NotificationRoute(AppRoutes.adminApprovalsName);
  }
  if (type.startsWith('escalation') || escalationId != null) {
    return const NotificationRoute(AppRoutes.adminEscalationsName);
  }
  if (orderId != null) {
    return NotificationRoute(AppRoutes.adminOrderDetailName, {'id': '$orderId'});
  }
  if (destinationId != null) {
    return NotificationRoute(
      AppRoutes.driverDestinationName,
      {'id': '$destinationId'},
    );
  }
  if (type == 'admin.order_created' || type == 'admin.workshop_rejected') {
    return const NotificationRoute(AppRoutes.adminOrdersName);
  }
  return null;
}

/// Pulls an int id out of an FCM `data` map (values arrive as strings).
int? notificationDataInt(Map<String, dynamic> data, String key) {
  final raw = data[key];
  if (raw is int) return raw;
  return int.tryParse(raw?.toString() ?? '');
}

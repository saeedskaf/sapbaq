import 'package:sapbaq/app/router/app_routes.dart';

/// A resolved deep-link target for a tapped notification.
class NotificationRoute {
  final String name;
  final Map<String, String> pathParameters;

  /// Screens that select a tab or focus a row take it here (`?request=7`).
  final Map<String, String> queryParameters;

  const NotificationRoute(
    this.name, [
    this.pathParameters = const {},
    this.queryParameters = const {},
  ]);
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
  int? contributionId,
  int? equipmentRequestId,
}) {
  if (ticketId != null) {
    return NotificationRoute(AppRoutes.ticketDetailName, {'id': '$ticketId'});
  }
  if (type.startsWith('support.')) {
    return const NotificationRoute(AppRoutes.supportName);
  }
  // Catalogue equipment (`equip_order.*`) → «طلبات المعدّات». Checked before
  // the contribution and order branches: an approval push is the one that
  // opens the 48-hour payment window, so it must land where the pay button is
  // — on the request itself when the push named one.
  if (type.startsWith('equip_order') || equipmentRequestId != null) {
    return NotificationRoute(AppRoutes.equipmentRequestsName, const {}, {
      if (equipmentRequestId != null) 'request': '$equipmentRequestId',
    });
  }
  // Marketplace contribution (payment confirmation / fulfilment) → «مساهماتي».
  if (type == 'contribution' || contributionId != null) {
    // Straight to the contribution when we know which one; «طلباتي» otherwise.
    return contributionId != null
        ? NotificationRoute(AppRoutes.contributionDetailName, {
            'id': '$contributionId',
          })
        : const NotificationRoute(AppRoutes.ordersName);
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

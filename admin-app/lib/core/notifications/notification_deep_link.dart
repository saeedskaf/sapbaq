import 'package:sapbaq_admin/app/router/app_routes.dart';

/// A resolved deep-link target for a tapped notification.
class NotificationRoute {
  final String name;
  final Map<String, String> pathParameters;
  final Map<String, String> queryParameters;
  const NotificationRoute(
    this.name, [
    this.pathParameters = const {},
    this.queryParameters = const {},
  ]);
}

/// Who is reading the notification — one enum per shell the router gates.
///
/// The backend sends one type per event and leaves the target to the app
/// (deep-link contract §B.1 #4): the same `maintenance.status` + `case_id` is an
/// operations-center case for staff and a «بلاغاتي» row for the imam who
/// reported it. Resolving with the wrong audience sends the reader to a screen
/// their role can't open, and the router's redirect bounces them to their shell,
/// so the tap silently does nothing.
enum NotificationAudience {
  /// Office/back-office roles — the admin shell (`/admin/*`, `/ops/*`).
  staff,

  /// The workshop (`SERVICE_HANDLER`) — the driver shell (`/driver/*`) only.
  serviceHandler,

  /// The imam (`MOSQUE_REP`) — the rep shell (`/rep/*`) only.
  mosqueRep,
}

/// Maps a notification's type + ids to the screen it should open (§14), for the
/// shell [audience] is in. Returns null when there's nothing specific to open.
/// Used by both the in-app inbox and a tapped system push, so they behave
/// identically.
NotificationRoute? resolveNotificationRoute(
  String type, {
  NotificationAudience audience = NotificationAudience.staff,
  int? orderId,
  int? destinationId,
  int? approvalId,
  int? escalationId,
  int? maintenanceCaseId,
  int? equipmentRequestId,
  int? waterFlagId,
  int? contributionId,
  int? catalogOrderId,
}) {
  if (audience == NotificationAudience.mosqueRep) {
    return _repRoute(
      type,
      maintenanceCaseId: maintenanceCaseId,
      equipmentRequestId: equipmentRequestId,
      waterFlagId: waterFlagId,
    );
  }
  // The workshop's shell holds nothing but its deliveries, and `/admin/*` is
  // redirected away from it — a destination is the only thing it can open.
  if (audience == NotificationAudience.serviceHandler) {
    return destinationId == null
        ? null
        : NotificationRoute(AppRoutes.driverDestinationName, {
            'id': '$destinationId',
          });
  }

  if (type.startsWith('pending_approval') || approvalId != null) {
    return const NotificationRoute(AppRoutes.adminApprovalsName);
  }
  if (type.startsWith('escalation') || escalationId != null) {
    return const NotificationRoute(AppRoutes.adminEscalationsName);
  }

  // Catalogue equipment orders (`equip_order.*`). Checked before everything
  // below because the generic `equipment` branch would otherwise swallow them
  // and open the imam's request queue — a different queue entirely.
  if (type.startsWith('equip_order') || catalogOrderId != null) {
    return const NotificationRoute(AppRoutes.opsCatalogOrdersName);
  }

  // --- Operations center (§4/§5): open the specific case or its queue. ---
  // Maintenance carries `case_id` → open that case; otherwise fall to its box.
  if (maintenanceCaseId != null) {
    return NotificationRoute(AppRoutes.opsMaintenanceDetailName, {
      'id': '$maintenanceCaseId',
    });
  }
  if (type.contains('maintenance')) {
    return const NotificationRoute(AppRoutes.opsMaintenanceName);
  }
  // Equipment-request / water-flag / contribution have only queue screens.
  if (equipmentRequestId != null || type.contains('equipment')) {
    return const NotificationRoute(AppRoutes.opsEquipmentRequestsName);
  }
  if (waterFlagId != null || type.contains('water')) {
    return const NotificationRoute(AppRoutes.opsWaterFlagsName);
  }
  // Marketplace field work now runs on fulfilment tasks (unified-dispatch
  // doc §1) — a funded contribution or a task assignment both land on the
  // queue, which is where the receiver acts.
  if (contributionId != null ||
      type.contains('fulfilment') ||
      type.contains('contribution') ||
      type.contains('marketplace')) {
    return const NotificationRoute(AppRoutes.opsFulfilmentTasksName);
  }

  // Order-scoped types (`admin.order_created`, `admin.workshop_rejected`,
  // `workshop.assigned`, `team.order_assigned`) all carry `order_id` — the
  // office reads them on the order, not on the delivery (the driver shell is
  // redirected away from this role, so a destination is never its target).
  if (orderId != null) {
    return NotificationRoute(AppRoutes.adminOrderDetailName, {
      'id': '$orderId',
    });
  }
  if (type == 'admin.order_created' || type == 'admin.workshop_rejected') {
    return const NotificationRoute(AppRoutes.adminOrdersName);
  }
  return null;
}

/// The imam's shell has no per-case detail route — «بلاغاتي» is a three-tab
/// screen (maintenance / water / equipment) covering every one of their
/// notifications, so land on the tab holding the row they were told about.
NotificationRoute? _repRoute(
  String type, {
  int? maintenanceCaseId,
  int? equipmentRequestId,
  int? waterFlagId,
}) {
  // Order matters: `need.water_fulfilled` and `need.equipment_installed` both
  // sit under `need.`, and only the id/keyword tells the tabs apart.
  if (type.startsWith('maintenance') || maintenanceCaseId != null) {
    return _repReports(AppRoutes.repReportsTabMaintenance);
  }
  if (waterFlagId != null || type.contains('water')) {
    return _repReports(AppRoutes.repReportsTabWater);
  }
  if (equipmentRequestId != null || type.contains('equipment')) {
    return _repReports(AppRoutes.repReportsTabEquipment);
  }
  // `rep.approved` — nothing to open but the shell itself.
  if (type.startsWith('rep.')) {
    return const NotificationRoute(AppRoutes.repMosqueName);
  }
  return null;
}

NotificationRoute _repReports(String tab) => NotificationRoute(
  AppRoutes.repReportsName,
  const {},
  {AppRoutes.repReportsTabQuery: tab},
);

/// Resolves a tapped push's raw FCM `data` for [audience].
///
/// Kept here rather than in the push service because the audience isn't known
/// when the push arrives: a cold launch resolves the session (and with it the
/// role) after the tap, so the payload is held and resolved at navigation time.
NotificationRoute? resolveNotificationData(
  Map<String, dynamic> data, {
  required NotificationAudience audience,
}) {
  // `notification_type` is the type; `data.type` is only a sub-discriminator on
  // some payloads (contract §B.1 #1), so it's the fallback, not the source.
  final type = (data['notification_type'] ?? data['type'] ?? '').toString();
  int? firstOf(List<String> keys) {
    for (final key in keys) {
      final value = notificationDataInt(data, key);
      if (value != null) return value;
    }
    return null;
  }

  return resolveNotificationRoute(
    type,
    audience: audience,
    orderId: notificationDataInt(data, 'order_id'),
    destinationId: notificationDataInt(data, 'destination_id'),
    approvalId: notificationDataInt(data, 'approval_id'),
    escalationId: notificationDataInt(data, 'escalation_id'),
    maintenanceCaseId: firstOf([
      'case_id',
      'maintenance_id',
      'maintenance_case_id',
    ]),
    equipmentRequestId: firstOf(['equipment_request_id', 'equipment_request']),
    waterFlagId: firstOf(['water_flag_id', 'water_flag']),
    contributionId: notificationDataInt(data, 'contribution_id'),
    catalogOrderId: notificationDataInt(data, 'equipment_request_id'),
  );
}

/// The audience for the signed-in [userType] — see [NotificationAudience].
/// Mirrors the shell the router's redirect puts each role in.
NotificationAudience audienceForRole({
  required bool isMosqueRep,
  required bool isServiceHandler,
}) {
  if (isMosqueRep) return NotificationAudience.mosqueRep;
  if (isServiceHandler) return NotificationAudience.serviceHandler;
  return NotificationAudience.staff;
}

/// Pulls an int id out of an FCM `data` map (values arrive as strings).
int? notificationDataInt(Map<String, dynamic> data, String key) {
  final raw = data[key];
  if (raw is int) return raw;
  return int.tryParse(raw?.toString() ?? '');
}

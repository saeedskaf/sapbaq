import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/notifications/notification_deep_link.dart';

/// Deep-link routing against the backend's notification contract
/// (BACKEND_REPLY_NOTIFICATIONS_INBOX_LANG_AND_DEEPLINKS §B): the backend sends
/// one type per event, so the same payload must land the imam and the staff
/// member on different screens.
void main() {
  group('staff (operations center)', () {
    test('a maintenance notification opens its case', () {
      final route = resolveNotificationRoute(
        'maintenance.awaiting_verification',
        maintenanceCaseId: 42,
      );

      expect(route?.name, AppRoutes.opsMaintenanceDetailName);
      expect(route?.pathParameters, {'id': '42'});
    });

    test('a new water flag opens the water queue', () {
      final route = resolveNotificationRoute('need.water_new', waterFlagId: 7);

      expect(route?.name, AppRoutes.opsWaterFlagsName);
    });

    test('a new equipment request opens the equipment queue', () {
      final route = resolveNotificationRoute(
        'need.equipment_new',
        equipmentRequestId: 9,
      );

      expect(route?.name, AppRoutes.opsEquipmentRequestsName);
    });

    test('a paid contribution opens the fulfilment-task queue', () {
      // Field work moved to fulfilment tasks (unified-dispatch doc §0) — the
      // contributions screen is a view-only ledger, so the push lands where
      // the receiver can act.
      final route = resolveNotificationRoute(
        'marketplace.paid',
        contributionId: 3,
      );

      expect(route?.name, AppRoutes.opsFulfilmentTasksName);
    });
  });

  group('workshop (service handler)', () {
    test('an assigned delivery opens the destination, not the order', () {
      // `workshop.assigned` carries both ids. Resolving it to the order would
      // send the workshop to `/admin/order/:id`, which its role can't open —
      // the router bounces it home and the tap does nothing.
      final route = resolveNotificationRoute(
        'workshop.assigned',
        audience: NotificationAudience.serviceHandler,
        orderId: 42,
        destinationId: 8,
      );

      expect(route?.name, AppRoutes.driverDestinationName);
      expect(route?.pathParameters, {'id': '8'});
    });

    test('an order-only notification opens nothing for the workshop', () {
      final route = resolveNotificationRoute(
        'admin.order_created',
        audience: NotificationAudience.serviceHandler,
        orderId: 42,
      );

      expect(route, isNull);
    });

    test('the office reads the same assignment on the order', () {
      final route = resolveNotificationRoute(
        'workshop.assigned',
        orderId: 42,
        destinationId: 8,
      );

      expect(route?.name, AppRoutes.adminOrderDetailName);
      expect(route?.pathParameters, {'id': '42'});
    });
  });

  group('audienceForRole', () {
    test('maps each role to its shell', () {
      expect(
        audienceForRole(isMosqueRep: true, isServiceHandler: false),
        NotificationAudience.mosqueRep,
      );
      expect(
        audienceForRole(isMosqueRep: false, isServiceHandler: true),
        NotificationAudience.serviceHandler,
      );
      expect(
        audienceForRole(isMosqueRep: false, isServiceHandler: false),
        NotificationAudience.staff,
      );
    });
  });

  group('mosque rep (imam)', () {
    test('a maintenance update opens «بلاغاتي» on the maintenance tab', () {
      final route = resolveNotificationRoute(
        'maintenance.status',
        audience: NotificationAudience.mosqueRep,
        maintenanceCaseId: 42,
      );

      expect(route?.name, AppRoutes.repReportsName);
      expect(route?.queryParameters, {
        AppRoutes.repReportsTabQuery: AppRoutes.repReportsTabMaintenance,
      });
    });

    test('an equipment decision opens the equipment tab', () {
      final route = resolveNotificationRoute(
        'need.equipment_approved',
        audience: NotificationAudience.mosqueRep,
        equipmentRequestId: 9,
      );

      expect(route?.name, AppRoutes.repReportsName);
      expect(route?.queryParameters, {
        AppRoutes.repReportsTabQuery: AppRoutes.repReportsTabEquipment,
      });
    });

    test('a fulfilled water flag opens the water tab', () {
      final route = resolveNotificationRoute(
        'need.water_fulfilled',
        audience: NotificationAudience.mosqueRep,
        waterFlagId: 7,
      );

      expect(route?.name, AppRoutes.repReportsName);
      expect(route?.queryParameters, {
        AppRoutes.repReportsTabQuery: AppRoutes.repReportsTabWater,
      });
    });

    test('account approval opens the rep shell', () {
      final route = resolveNotificationRoute(
        'rep.approved',
        audience: NotificationAudience.mosqueRep,
      );

      expect(route?.name, AppRoutes.repMosqueName);
    });

    test('a staff-only notification opens nothing for the imam', () {
      final route = resolveNotificationRoute(
        'pending_approval.created',
        audience: NotificationAudience.mosqueRep,
        approvalId: 5,
      );

      expect(route, isNull);
    });
  });

  group('resolveNotificationData', () {
    test('reads the ids FCM delivers as strings', () {
      final route = resolveNotificationData({
        'notification_type': 'maintenance.new_case',
        'case_id': '42',
      }, audience: NotificationAudience.staff);

      expect(route?.name, AppRoutes.opsMaintenanceDetailName);
      expect(route?.pathParameters, {'id': '42'});
    });

    test('routes the same payload by audience', () {
      final payload = {
        'notification_type': 'maintenance.status',
        'case_id': '42',
        'equipment_code': 'EQ-1',
      };

      expect(
        resolveNotificationData(
          payload,
          audience: NotificationAudience.staff,
        )?.name,
        AppRoutes.opsMaintenanceDetailName,
      );
      expect(
        resolveNotificationData(
          payload,
          audience: NotificationAudience.mosqueRep,
        )?.name,
        AppRoutes.repReportsName,
      );
    });

    test('`data.type` is a sub-discriminator, not the type', () {
      // A customer-facing shape; for staff it still resolves by its id.
      final route = resolveNotificationData({
        'type': 'contribution',
        'contribution_id': '3',
      }, audience: NotificationAudience.staff);

      expect(route?.name, AppRoutes.opsFulfilmentTasksName);
    });

    test('an escalation with no order opens the escalations queue', () {
      // `escalation.*` sends `order_id: ""` when it isn't tied to an order
      // (backend reply 2026-07-16 §1) — the empty string must read as "no id",
      // not open order 0.
      final route = resolveNotificationData({
        'notification_type': 'escalation.created',
        'escalation_id': '5',
        'order_id': '',
      }, audience: NotificationAudience.staff);

      expect(route?.name, AppRoutes.adminEscalationsName);
    });

    test('ready-to-claim opens the case for a team leader', () {
      // `maintenance.ready_to_claim` fans out to every team leader in the
      // mosque's governorate, carrying `case_id` (manager-direct doc §6) — the
      // claim button lives on the case, so that's where the tap must land.
      final route = resolveNotificationData({
        'notification_type': 'maintenance.ready_to_claim',
        'case_id': '90',
        'equipment_code': '8801020301',
      }, audience: NotificationAudience.staff);

      expect(route?.name, AppRoutes.opsMaintenanceDetailName);
      expect(route?.pathParameters['id'], '90');
    });

    test('a manager-raised need opens the imam\'s matching tab', () {
      final water = resolveNotificationData({
        'notification_type': 'need.water_direct',
      }, audience: NotificationAudience.mosqueRep);
      expect(water?.name, AppRoutes.repReportsName);
      expect(
        water?.queryParameters[AppRoutes.repReportsTabQuery],
        AppRoutes.repReportsTabWater,
      );

      final equipment = resolveNotificationData({
        'notification_type': 'need.equipment_direct',
      }, audience: NotificationAudience.mosqueRep);
      expect(equipment?.name, AppRoutes.repReportsName);
      expect(
        equipment?.queryParameters[AppRoutes.repReportsTabQuery],
        AppRoutes.repReportsTabEquipment,
      );
    });

    test('a catalogue-order push opens its own queue, not the imam\'s', () {
      // `equip_order.*` and the imam's `need.equipment_*` are different queues;
      // the generic "equipment" match must not swallow the catalogue ones.
      final route = resolveNotificationData({
        'notification_type': 'equip_order.new',
        'equipment_request_id': '7',
      }, audience: NotificationAudience.staff);

      expect(route?.name, AppRoutes.opsCatalogOrdersName);
    });

    test('an unknown payload opens nothing', () {
      final route = resolveNotificationData({
        'notification_type': 'something.new',
      }, audience: NotificationAudience.staff);

      expect(route, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/features/admin/data/models/catalog_order.dart';
import 'package:sapbaq_admin/features/admin/data/models/ops_counts.dart';
import 'package:sapbaq_admin/features/admin/data/models/mosque_need.dart';

/// Parsing of the moderation payloads (water flags, equipment requests) — real
/// shapes taken from live `GET` responses.
void main() {
  test('parses an equipment request with a nested mosque', () {
    final r = AdminEquipmentRequest.fromJson({
      'id': 2,
      'mosque': {
        'id': 8680,
        'code': '020802',
        'name': 'مسجد سبيكة',
        'area': 'الشهداء',
        'governorate': 'حولي',
      },
      'equipment_type': 'ثلاجة',
      'equipment_type_code': '77',
      'note': 'ملاحظة',
      'status': 'submitted',
      'reject_reason': '',
      'created_at': '2026-07-13T14:08:20+03:00',
    });

    expect(r.equipmentType, 'ثلاجة');
    expect(r.status, 'SUBMITTED');
    expect(r.isSubmitted, isTrue);
    expect(r.mosque?.name, 'مسجد سبيكة');
    expect(r.mosque?.locationLine, 'الشهداء، حولي');
  });

  test('parses a water flag and reports its actionable state', () {
    final f = AdminWaterFlag.fromJson({
      'id': 3,
      'mosque': {'id': 8680, 'name': 'مسجد سبيكة', 'governorate': 'حولي'},
      'status': 'APPROVED',
      'created_at': '2026-07-13T13:34:28+03:00',
      'approved_at': '2026-07-13T15:00:00+03:00',
      'fulfilled_at': null,
    });

    expect(f.status, 'APPROVED');
    expect(f.isSubmitted, isFalse);
    expect(f.mosque?.locationLine, 'حولي');
    expect(f.approvedAt, isNotNull);
  });

  test('tolerates a missing mosque object', () {
    final f = AdminWaterFlag.fromJson({'id': 9, 'status': 'SUBMITTED'});
    expect(f.mosque, isNull);
    expect(f.isSubmitted, isTrue);
  });

  group('catalogue order actions (non-live equipment)', () {
    Set<CatalogOrderAction> manager(String status) =>
        visibleCatalogOrderActions(
          status: status,
          isManager: true,
          isAssignedLeader: false,
          isAssignedHandler: false,
        );

    test('a new order is approved or rejected, nothing else', () {
      expect(manager('UNDER_REVIEW'), {
        CatalogOrderAction.approve,
        CatalogOrderAction.reject,
      });
    });

    test('an approved order waits — dispatch only starts once it is paid', () {
      // The customer has 48 hours and may never pay; assigning a team to an
      // order that can still evaporate would waste the leader's time.
      expect(manager('APPROVED'), isEmpty);
      expect(manager('PAID'), {CatalogOrderAction.assignLeader});
    });

    test('the assigned leader distributes, and may install himself', () {
      final leader = visibleCatalogOrderActions(
        status: 'ASSIGNED',
        isManager: false,
        isAssignedLeader: true,
        isAssignedHandler: false,
      );
      expect(leader, {
        CatalogOrderAction.assignHandler,
        CatalogOrderAction.install,
      });
    });

    test('the assigned handler can only record the installation', () {
      final handler = visibleCatalogOrderActions(
        status: 'ASSIGNED',
        isManager: false,
        isAssignedLeader: false,
        isAssignedHandler: true,
      );
      expect(handler, {CatalogOrderAction.install});
    });

    test('an unrelated staff member sees nothing', () {
      for (final s in CatalogOrderEnums.statuses) {
        expect(
          visibleCatalogOrderActions(
            status: s,
            isManager: false,
            isAssignedLeader: false,
            isAssignedHandler: false,
          ),
          isEmpty,
          reason: s,
        );
      }
    });

    test('terminal orders expose nothing, even to a manager', () {
      for (final s in ['INSTALLED', 'REJECTED', 'CANCELLED']) {
        expect(manager(s), isEmpty, reason: s);
      }
    });
  });

  test('a catalogue order reads its item and dispatch chain', () {
    final o = CatalogOrder.fromJson({
      'id': 7,
      'code': 'EQR-00007',
      'status': 'ASSIGNED',
      'unit_price': '120.00',
      'product': {'id': 8, 'name': 'مبرّد فاخر'},
      'variant': {'id': 81, 'name': 'حوضان — عادي'},
      'mosque': {'id': 12, 'name': 'مسجد النور', 'area': 'القبلة'},
      'team_leader': {'id': 4, 'full_name': 'قائد'},
      'assigned_to': {'id': 9, 'full_name': 'منفّذ'},
      'installed_code': '',
    });

    expect(o.modelName, 'مبرّد فاخر — حوضان — عادي');
    expect(o.teamLeader?.id, 4);
    expect(o.assignedTo?.id, 9);
    expect(o.mosque?.name, 'مسجد النور');
  });

  test('a catalogue order still renders on the pre-unification shape', () {
    final o = CatalogOrder.fromJson({
      'id': 7,
      'code': 'EQR-00007',
      'status': 'ASSIGNED',
      'unit_price': '120.00',
      'equipment_model': {'id': 8, 'name': 'مبرّد فاخر', 'sink_count': 2},
      'mosque': {'id': 12, 'name': 'مسجد النور'},
    });

    expect(o.modelName, 'مبرّد فاخر');
  });

  test('the catalogue queue counts toward the operations badge', () {
    final counts = OpsCounts.fromJson({
      'maintenance': 2,
      'water_flags': 1,
      'equipment_requests': 0,
      'contributions': 3,
      'catalog_orders': 4,
    });

    expect(counts.catalogOrders, 4);
    // The badge is one number for everything waiting — a queue missing from
    // the total is a queue nobody notices.
    expect(counts.total, 10);
  });

  test('an older counts payload without the field still parses', () {
    final counts = OpsCounts.fromJson({'maintenance': 1});
    expect(counts.catalogOrders, 0);
    expect(counts.total, 1);
  });
}

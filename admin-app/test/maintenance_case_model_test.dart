import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/core/utils/distance.dart';
import 'package:sapbaq_admin/features/admin/data/models/maintenance_case.dart';

/// Parsing of the admin maintenance case — the fields whose names differ from
/// our first assumptions (team_leader/team_member, string equipment fields,
/// photos as {image}).
void main() {
  test('parses the admin case shape', () {
    final c = MaintenanceCase.fromJson({
      'id': 42,
      'reference': '6f1e2c9a-aaaa-bbbb-cccc-dddddddddddd',
      'channel': 'REP',
      'equipment': {
        'id': 7,
        'code': '1002000345',
        'equipment_type': 'برّاد مياه',
        'mosque': 'مسجد النور',
      },
      'reported_by': {'id': 12, 'full_name': 'إمام', 'phone': '+965'},
      'issue_type': 'NOT_WORKING',
      'priority': 'MEDIUM',
      'status': 'APPROVED',
      'external_status': 'IN_PROGRESS',
      'cost_path': 'CUSTOMER_PAID',
      'price': '8.60',
      'suggested_cost_path': 'CUSTOMER_PAID',
      'team_leader': {'id': 20, 'full_name': 'قائد', 'phone': '+965'},
      'team_member': {'id': 33, 'full_name': 'عضو', 'phone': '+965'},
      'photos': [
        {'id': 1, 'image': 'https://host/media/maintenance/a.jpg'},
      ],
      'created_at': '2026-07-13T09:00:00Z',
    });

    // Equipment fields are plain strings (not nested objects).
    expect(c.equipment?.equipmentType, 'برّاد مياه');
    expect(c.equipment?.mosque, 'مسجد النور');
    // Person objects come from team_leader / team_member (not assigned_*).
    expect(c.teamLeader?.id, 20);
    expect(c.teamMember?.fullName, 'عضو');
    expect(c.price, '8.60');
    expect(c.costPath, 'CUSTOMER_PAID');
    expect(c.externalStatus, 'IN_PROGRESS');
    expect(c.photoUrls, ['https://host/media/maintenance/a.jpg']);
    expect(c.shortReference, '6F1E2C9A');
  });

  test('defaults cost path to UNSET and tolerates missing people', () {
    final c = MaintenanceCase.fromJson({
      'id': 1,
      'channel': 'QR_CUSTOMER',
      'issue_type': 'LEAKING',
      'status': 'SUBMITTED',
    });
    expect(c.costPath, 'UNSET');
    expect(c.teamLeader, isNull);
    expect(c.teamMember, isNull);
    expect(c.photoUrls, isEmpty);
    expect(c.isQrCustomer, isTrue);
  });

  group('manager channel & claimability', () {
    test('a manager case is born APPROVED with no leader, so it is claimable', () {
      final c = MaintenanceCase.fromJson({
        'id': 90,
        'channel': 'MANAGER',
        'status': 'APPROVED',
        'team_leader': null,
      });
      expect(c.isManagerChannel, isTrue);
      expect(c.isClaimable, isTrue);
    });

    test('once a leader has it, it is no longer claimable', () {
      final c = MaintenanceCase.fromJson({
        'id': 90,
        'status': 'APPROVED',
        'team_leader': {'id': 4, 'full_name': 'قائد'},
      });
      expect(c.isClaimable, isFalse);
    });

    test('an unassigned case in any other status is not claimable', () {
      for (final s in ['SUBMITTED', 'ACKNOWLEDGED', 'ASSIGNED', 'RESOLVED']) {
        final c = MaintenanceCase.fromJson({'id': 1, 'status': s});
        expect(c.isClaimable, isFalse, reason: s);
      }
    });
  });

  group('nearest-first fields', () {
    test('distance and maps url are read off the row', () {
      final c = MaintenanceCase.fromJson({
        'id': 42,
        'status': 'IN_PROGRESS',
        'distance_km': 1.52,
        'mosque_maps_url': 'https://maps.example/?q=29.31,47.91',
      });
      expect(c.distanceKm, 1.52);
      expect(c.mosqueMapsUrl, 'https://maps.example/?q=29.31,47.91');
    });

    test('a string distance is accepted too (payload type unconfirmed)', () {
      final c = MaintenanceCase.fromJson({
        'id': 42,
        'status': 'IN_PROGRESS',
        'distance_km': '2.75',
      });
      expect(c.distanceKm, 2.75);
    });

    test('no location sent, or a mosque without coordinates, reads as null', () {
      expect(MaintenanceCase.fromJson({'id': 1}).distanceKm, isNull);
      expect(
        MaintenanceCase.fromJson({'id': 1, 'distance_km': null}).distanceKm,
        isNull,
      );
      // An empty maps url is the same as none — the button must not render.
      expect(
        MaintenanceCase.fromJson({'id': 1, 'mosque_maps_url': ''}).mosqueMapsUrl,
        isNull,
      );
    });

    test('the badge keeps one decimal under 10 km and rounds above', () {
      expect(formatDistanceKm(1.52), '1.5');
      expect(formatDistanceKm(9.99), '10.0');
      expect(formatDistanceKm(12.4), '12');
      expect(formatDistanceKm(-1), '');
    });
  });
}

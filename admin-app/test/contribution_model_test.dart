import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/features/admin/data/models/contribution.dart';

/// Parsing of admin contributions, including the kind-specific `details`
/// summary used on the queue card.
void main() {
  test('parses an equipment contribution and summarizes details', () {
    final c = AdminContribution.fromJson({
      'id': 15,
      'reference': 'abc-uuid',
      'kind': 'EQUIPMENT',
      'status': 'PAID',
      'customer': {'id': 99, 'full_name': 'متبرّع', 'phone': '+965'},
      'mosque': {'id': 3, 'name': 'مسجد النور', 'governorate': 'حولي'},
      'amount': '45.00',
      'details': {
        'equipment_request_id': 7,
        'equipment_type': 'برّاد مياه',
        'model': {'id': 8, 'name': 'X', 'image': 'https://h/x.jpg'},
      },
      'proof_photo': null,
      'created_at': '2026-07-13T09:00:00Z',
      'paid_at': '2026-07-13T09:05:00Z',
    });

    expect(c.kind, 'EQUIPMENT');
    expect(c.isPaid, isTrue);
    expect(c.mosque?.name, 'مسجد النور');
    expect(c.detailSummary, 'برّاد مياه');
    expect(c.proofPhoto, isNull);
  });

  test('summarizes water and maintenance details', () {
    final water = AdminContribution.fromJson({
      'id': 1,
      'kind': 'WATER',
      'status': 'PAID',
      'details': {'packages': 5, 'package_label': 'كرتون مياه'},
    });
    expect(water.detailSummary, '5 × كرتون مياه');

    final maint = AdminContribution.fromJson({
      'id': 2,
      'kind': 'MAINTENANCE',
      'status': 'PAID',
      'details': {'case_id': 12, 'equipment_code': '100', 'description': 'تسريب'},
    });
    expect(maint.detailSummary, '100 — تسريب');
  });
}

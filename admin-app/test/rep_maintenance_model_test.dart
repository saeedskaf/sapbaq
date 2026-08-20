import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/features/rep/data/models/rep_models.dart';

/// Parsing of the maintenance report payload — the nested `equipment` object and
/// the `photos` array added for the #2 diagnostic-photos feature.
void main() {
  test('parses nested equipment and photo URLs', () {
    final report = RepMaintenanceReport.fromJson({
      'id': 5,
      'reference': 'cd134ab2-5ec8-41a7-a6de-534506e05718',
      'equipment': {
        'id': 8,
        'code': '8802080201',
        'equipment_type': 'مبرّد ماء',
      },
      'issue_type': 'LEAKING',
      'issue_type_display': 'تسريب',
      'status': 'SUBMITTED',
      'photos': [
        {'id': 1, 'image': 'https://host/media/maintenance/a.png'},
        {'id': 2, 'image': 'https://host/media/maintenance/b.jpg'},
      ],
      'created_at': '2026-07-13T13:42:28+03:00',
    });

    expect(report.equipmentCode, '8802080201');
    expect(report.equipmentType, 'مبرّد ماء');
    expect(report.issueTypeDisplay, 'تسريب');
    expect(report.shortReference, 'CD134AB2');
    expect(report.photos, hasLength(2));
    expect(report.photos.first.id, 1);
    expect(report.photos.first.imageUrl, 'https://host/media/maintenance/a.png');
  });

  test('tolerates a missing/empty photos array', () {
    final report = RepMaintenanceReport.fromJson({
      'id': 6,
      'equipment': {'code': '111'},
      'issue_type': 'NOT_WORKING',
      'status': 'RESOLVED',
    });
    expect(report.photos, isEmpty);
    expect(report.status, RepReportStatus.resolved);
  });

  test('drops photo entries with a blank URL', () {
    final report = RepMaintenanceReport.fromJson({
      'id': 7,
      'equipment': {'code': '222'},
      'issue_type': 'OTHER',
      'status': 'SUBMITTED',
      'photos': [
        {'id': 1, 'image': ''},
        {'id': 2, 'image': 'https://host/x.webp'},
      ],
    });
    expect(report.photos, hasLength(1));
    expect(report.photos.single.id, 2);
  });
}

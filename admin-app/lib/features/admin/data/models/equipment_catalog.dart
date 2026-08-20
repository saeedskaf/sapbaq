import 'package:equatable/equatable.dart';

/// `GET /admin/equipment-types/` — a pickable equipment type for the manager's
/// direct equipment request (FLUTTER_MANAGER_DIRECT_PROVISION §3).
class EquipmentTypeOption extends Equatable {
  final int id;
  final String name;

  const EquipmentTypeOption({required this.id, this.name = ''});

  factory EquipmentTypeOption.fromJson(Map<String, dynamic> j) =>
      EquipmentTypeOption(
        id: j['id'] as int? ?? 0,
        name: (j['name'] ?? '').toString(),
      );

  @override
  List<Object?> get props => [id, name];
}

/// `GET /admin/maintenance-equipment/?mosque_id=` — a unit installed at the
/// picked mosque, for the manager's direct maintenance report (§4.1).
///
/// [suggestedCostPath] is the backend's proposal (warranty-aware) and seeds the
/// form's cost-path field; the manager may override it.
class MaintenanceEquipmentUnit extends Equatable {
  final int id;
  final String code;
  final String equipmentType;
  final int unitNumber;
  final String status;
  final bool inWarranty;
  final String suggestedCostPath;

  const MaintenanceEquipmentUnit({
    required this.id,
    this.code = '',
    this.equipmentType = '',
    this.unitNumber = 0,
    this.status = '',
    this.inWarranty = false,
    this.suggestedCostPath = '',
  });

  factory MaintenanceEquipmentUnit.fromJson(Map<String, dynamic> j) =>
      MaintenanceEquipmentUnit(
        id: j['id'] as int? ?? 0,
        code: (j['code'] ?? '').toString(),
        equipmentType: (j['equipment_type'] ?? '').toString(),
        unitNumber: j['unit_number'] as int? ?? 0,
        status: (j['status'] ?? '').toString().toUpperCase(),
        inWarranty: j['in_warranty'] == true,
        suggestedCostPath: (j['suggested_cost_path'] ?? '')
            .toString()
            .toUpperCase(),
      );

  /// "مبرّد مياه — 8801020301" for the picker row, falling back to whichever
  /// part is present.
  String get label =>
      [equipmentType, code].where((s) => s.isNotEmpty).join(' — ');

  @override
  List<Object?> get props => [id, code, status, inWarranty, suggestedCostPath];
}

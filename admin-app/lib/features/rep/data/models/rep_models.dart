import 'package:equatable/equatable.dart';

/// Mosque-representative account states (ADMIN_APP_BACKEND_INTEGRATION §1.1).
enum RepStatus { pending, active, deactivated, unknown }

RepStatus repStatusFrom(String v) => switch (v.toUpperCase()) {
  'PENDING' => RepStatus.pending,
  'ACTIVE' => RepStatus.active,
  'DEACTIVATED' => RepStatus.deactivated,
  _ => RepStatus.unknown,
};

/// The rep's mosque as embedded in `GET /rep/me/` and the invite lookup.
class RepMosque extends Equatable {
  final int id;
  final String name;
  final String area;
  final String governorate;

  const RepMosque({
    required this.id,
    required this.name,
    this.area = '',
    this.governorate = '',
  });

  factory RepMosque.fromJson(Map<String, dynamic> j) => RepMosque(
    id: j['id'] as int? ?? 0,
    name: (j['name'] ?? '').toString(),
    area: (j['area'] ?? '').toString(),
    governorate: (j['governorate'] ?? '').toString(),
  );

  String get areaLine =>
      [area, governorate].where((s) => s.isNotEmpty).join('، ');

  @override
  List<Object?> get props => [id, name, area, governorate];
}

/// `GET /rep/me/` — the representative's profile, status, and mosque.
class RepProfile extends Equatable {
  final int id;
  final String phone;
  final String fullName;
  final RepStatus status;
  final RepMosque? mosque;

  const RepProfile({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.status,
    this.mosque,
  });

  factory RepProfile.fromJson(Map<String, dynamic> j) {
    final first = (j['first_name'] ?? '').toString();
    final last = (j['last_name'] ?? '').toString();
    final full = (j['full_name'] ?? '').toString();
    return RepProfile(
      id: j['id'] as int? ?? 0,
      phone: (j['phone'] ?? '').toString(),
      fullName: full.isNotEmpty ? full : '$first $last'.trim(),
      status: repStatusFrom((j['status'] ?? '').toString()),
      mosque: j['mosque'] is Map
          ? RepMosque.fromJson(Map<String, dynamic>.from(j['mosque'] as Map))
          : null,
    );
  }

  @override
  List<Object?> get props => [id, phone, fullName, status, mosque];
}

/// `GET /rep/invite/{token}/` — the mosque an invite is pre-bound to.
class RepInviteInfo extends Equatable {
  final RepMosque mosque;
  final String suggestedName;

  const RepInviteInfo({required this.mosque, this.suggestedName = ''});

  factory RepInviteInfo.fromJson(Map<String, dynamic> j) => RepInviteInfo(
    mosque: j['mosque'] is Map
        ? RepMosque.fromJson(Map<String, dynamic>.from(j['mosque'] as Map))
        : RepMosque(
            id: j['mosque_id'] as int? ?? 0,
            name: (j['mosque_name'] ?? '').toString(),
          ),
    suggestedName: (j['suggested_name'] ?? j['name'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [mosque, suggestedName];
}

/// `GET /rep/equipment/` — a unit registered to the rep's mosque. The 10-digit
/// [code] is the QR-plate identity the rep physically sees on the device.
class RepEquipmentUnit extends Equatable {
  final int id;
  final String code;
  final String typeName;

  const RepEquipmentUnit({
    required this.id,
    required this.code,
    this.typeName = '',
  });

  factory RepEquipmentUnit.fromJson(Map<String, dynamic> j) => RepEquipmentUnit(
    id: j['id'] as int? ?? 0,
    code: (j['code'] ?? j['equipment_code'] ?? '').toString(),
    typeName: (j['equipment_type'] ?? j['type'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [id, code, typeName];
}

/// A diagnostic photo attached to a maintenance report (`MaintenancePhoto`,
/// `related_name = photos`). [imageUrl] is an absolute URL from the API.
class RepPhoto extends Equatable {
  final int id;
  final String imageUrl;

  const RepPhoto({required this.id, required this.imageUrl});

  factory RepPhoto.fromJson(Map<String, dynamic> j) => RepPhoto(
    id: j['id'] as int? ?? 0,
    imageUrl: (j['image'] ?? j['image_url'] ?? j['url'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [id, imageUrl];
}

/// Reporter-facing statuses — deliberately only three (Maintenance spec §6).
enum RepReportStatus { submitted, inProgress, resolved, unknown }

RepReportStatus repReportStatusFrom(String v) => switch (v.toUpperCase()) {
  'SUBMITTED' => RepReportStatus.submitted,
  'IN_PROGRESS' => RepReportStatus.inProgress,
  'RESOLVED' => RepReportStatus.resolved,
  _ => RepReportStatus.unknown,
};

/// `GET /rep/maintenance/` — one of the rep's own maintenance reports. The
/// unit is delivered as a nested `equipment` object (code + type); the display
/// issue label comes from `issue_type_display` (already localized by the API).
class RepMaintenanceReport extends Equatable {
  final int id;
  final String reference;
  final String equipmentCode;
  final String equipmentType;
  final String issueType;
  final String issueTypeDisplay;
  final String description;
  final RepReportStatus status;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final List<RepPhoto> photos;

  /// Who filed it: `REP` (the imam himself), `QR_CUSTOMER`, or `MANAGER` — the
  /// list now also carries cases a regional/global manager raised for this
  /// mosque (manager-direct doc §5), which the imam never submitted.
  final String channel;

  const RepMaintenanceReport({
    required this.id,
    this.reference = '',
    required this.equipmentCode,
    this.equipmentType = '',
    required this.issueType,
    this.issueTypeDisplay = '',
    required this.description,
    required this.status,
    this.createdAt,
    this.resolvedAt,
    this.photos = const [],
    this.channel = '',
  });

  /// Raised by management for this mosque, not by the imam.
  bool get isFromManagement => channel == 'MANAGER';

  factory RepMaintenanceReport.fromJson(Map<String, dynamic> j) {
    final equip = j['equipment'] is Map
        ? Map<String, dynamic>.from(j['equipment'] as Map)
        : const <String, dynamic>{};
    final issue = (j['issue_type'] ?? '').toString();
    return RepMaintenanceReport(
      id: j['id'] as int? ?? 0,
      reference: (j['reference'] ?? '').toString(),
      equipmentCode: (equip['code'] ?? j['equipment_code'] ?? j['code'] ?? '')
          .toString(),
      equipmentType: (equip['equipment_type'] ?? equip['type'] ?? '')
          .toString(),
      issueType: issue,
      issueTypeDisplay: (j['issue_type_display'] ?? issue).toString(),
      description: (j['description'] ?? '').toString(),
      status: repReportStatusFrom((j['status'] ?? '').toString()),
      channel: (j['channel'] ?? '').toString().toUpperCase(),
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
      resolvedAt: DateTime.tryParse((j['resolved_at'] ?? '').toString()),
      photos:
          (j['photos'] as List?)
              ?.whereType<Map>()
              .map((e) => RepPhoto.fromJson(Map<String, dynamic>.from(e)))
              .where((p) => p.imageUrl.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  /// Short human-friendly reference — the first block of the UUID, upper-cased.
  String get shortReference =>
      reference.isEmpty ? '' : reference.split('-').first.toUpperCase();

  @override
  List<Object?> get props => [id, equipmentCode, issueType, status];
}

/// `GET /rep/water-flag/` — one of the rep's water-restock flags.
class RepWaterFlag extends Equatable {
  final int id;
  final String status; // SUBMITTED / APPROVED / FULFILLED / CANCELLED
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? fulfilledAt;

  const RepWaterFlag({
    required this.id,
    required this.status,
    this.createdAt,
    this.approvedAt,
    this.fulfilledAt,
  });

  factory RepWaterFlag.fromJson(Map<String, dynamic> j) => RepWaterFlag(
    id: j['id'] as int? ?? 0,
    status: (j['status'] ?? '').toString().toUpperCase(),
    createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
    approvedAt: DateTime.tryParse((j['approved_at'] ?? '').toString()),
    fulfilledAt: DateTime.tryParse((j['fulfilled_at'] ?? '').toString()),
  );

  bool get isOpen => status == 'SUBMITTED' || status == 'APPROVED';

  @override
  List<Object?> get props => [id, status];
}

/// `GET /rep/equipment-request/` — one of the rep's new-equipment requests.
class RepEquipmentRequest extends Equatable {
  final int id;
  final String typeName;
  final String note;
  final String
  status; // SUBMITTED / APPROVED / FULFILLED / REJECTED / CANCELLED
  final String rejectReason;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? fulfilledAt;

  const RepEquipmentRequest({
    required this.id,
    required this.typeName,
    this.note = '',
    required this.status,
    this.rejectReason = '',
    this.createdAt,
    this.approvedAt,
    this.fulfilledAt,
  });

  factory RepEquipmentRequest.fromJson(Map<String, dynamic> j) =>
      RepEquipmentRequest(
        id: j['id'] as int? ?? 0,
        typeName: (j['equipment_type'] ?? j['type'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
        status: (j['status'] ?? '').toString().toUpperCase(),
        rejectReason: (j['reject_reason'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
        approvedAt: DateTime.tryParse((j['approved_at'] ?? '').toString()),
        fulfilledAt: DateTime.tryParse((j['fulfilled_at'] ?? '').toString()),
      );

  @override
  List<Object?> get props => [id, typeName, status];
}

/// An orderable equipment type (water cooler / fridge / …) for the rep's
/// new-equipment request. Backed by the proposed `GET /rep/equipment-types/`
/// (Gap C).
class RepEquipmentType extends Equatable {
  final int id;
  final String name;

  const RepEquipmentType({required this.id, required this.name});

  factory RepEquipmentType.fromJson(Map<String, dynamic> j) => RepEquipmentType(
    id: j['id'] as int? ?? 0,
    name: (j['name'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [id, name];
}

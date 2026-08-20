import 'package:equatable/equatable.dart';

/// The mosque as embedded in mosque-needs moderation payloads (water flags,
/// equipment requests): `{id, code, name, area, governorate}`. Distinct from
/// the delivery `Mosque` (which carries coordinates instead of governorate).
class NeedMosque extends Equatable {
  final int id;
  final String code;
  final String name;
  final String area;
  final String governorate;

  /// Ready-to-open Google Maps link, when the mosque has coordinates — the
  /// "directions" button on a fulfilment task (sorting doc §2).
  final String? mapsUrl;

  const NeedMosque({
    required this.id,
    this.code = '',
    this.name = '',
    this.area = '',
    this.governorate = '',
    this.mapsUrl,
  });

  factory NeedMosque.fromJson(Map<String, dynamic> j) => NeedMosque(
    id: j['id'] as int? ?? 0,
    code: (j['code'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    area: (j['area'] ?? '').toString(),
    governorate: (j['governorate'] ?? '').toString(),
    mapsUrl: (j['maps_url'] as String?)?.isNotEmpty == true
        ? j['maps_url'] as String
        : null,
  );

  /// "area، governorate" — the parts that are present.
  String get locationLine =>
      [area, governorate].where((s) => s.isNotEmpty).join('، ');

  @override
  List<Object?> get props => [id, code, name, area, governorate];
}

/// `GET /admin/water-flags/` — a mosque water-shortage flag awaiting the
/// dispatch desk's approval (then donor funding, then fulfilment).
class AdminWaterFlag extends Equatable {
  final int id;
  final NeedMosque? mosque;
  final String status; // SUBMITTED | APPROVED | FULFILLED | CANCELLED
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? fulfilledAt;

  const AdminWaterFlag({
    required this.id,
    this.mosque,
    required this.status,
    this.createdAt,
    this.approvedAt,
    this.fulfilledAt,
  });

  bool get isSubmitted => status == 'SUBMITTED';

  factory AdminWaterFlag.fromJson(Map<String, dynamic> j) => AdminWaterFlag(
    id: j['id'] as int? ?? 0,
    mosque: j['mosque'] is Map
        ? NeedMosque.fromJson(Map<String, dynamic>.from(j['mosque'] as Map))
        : null,
    status: (j['status'] ?? '').toString().toUpperCase(),
    createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
    approvedAt: DateTime.tryParse((j['approved_at'] ?? '').toString()),
    fulfilledAt: DateTime.tryParse((j['fulfilled_at'] ?? '').toString()),
  );

  @override
  List<Object?> get props => [id, status];
}

/// `GET /admin/equipment-requests/` — an imam's request for a new unit,
/// approved/rejected by the regional manager (the dispatch desk may only
/// cancel).
class AdminEquipmentRequest extends Equatable {
  final int id;
  final NeedMosque? mosque;
  final String equipmentType;
  final String equipmentTypeCode;
  final String note;
  final String
  status; // SUBMITTED | APPROVED | FULFILLED | REJECTED | CANCELLED
  final String rejectReason;

  /// What the campaign funds — the product plus the picked combination, already
  /// composed by the server. Set at approval time, or at creation time when a
  /// manager raises the request directly. Empty until then.
  ///
  /// Falls back to the pre-unification `model.name` so an older server build
  /// still renders.
  final String itemLabel;

  /// The published funding goal (string money), mirroring [model]'s price.
  final String targetAmount;

  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? fulfilledAt;

  const AdminEquipmentRequest({
    required this.id,
    this.mosque,
    this.equipmentType = '',
    this.equipmentTypeCode = '',
    this.note = '',
    required this.status,
    this.rejectReason = '',
    this.itemLabel = '',
    this.targetAmount = '',
    this.createdAt,
    this.approvedAt,
    this.fulfilledAt,
  });

  bool get isSubmitted => status == 'SUBMITTED';

  /// "المنتج — التنويع", or whichever half arrived. Never assembled from raw
  /// attributes: the variant's name comes composed from the server.
  static String _itemLabel(Map<String, dynamic> j) {
    String name(dynamic v) => v is Map ? (v['name'] ?? '').toString() : '';
    final parts = [
      name(j['product']),
      name(j['variant']),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' — ') : name(j['model']);
  }

  factory AdminEquipmentRequest.fromJson(Map<String, dynamic> j) =>
      AdminEquipmentRequest(
        id: j['id'] as int? ?? 0,
        mosque: j['mosque'] is Map
            ? NeedMosque.fromJson(Map<String, dynamic>.from(j['mosque'] as Map))
            : null,
        equipmentType: (j['equipment_type'] ?? j['type'] ?? '').toString(),
        equipmentTypeCode: (j['equipment_type_code'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
        status: (j['status'] ?? '').toString().toUpperCase(),
        rejectReason: (j['reject_reason'] ?? '').toString(),
        itemLabel: _itemLabel(j),
        targetAmount: (j['target_amount'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
        approvedAt: DateTime.tryParse((j['approved_at'] ?? '').toString()),
        fulfilledAt: DateTime.tryParse((j['fulfilled_at'] ?? '').toString()),
      );

  @override
  List<Object?> get props => [
    id,
    status,
    rejectReason,
    itemLabel,
    targetAmount,
  ];
}

import 'package:equatable/equatable.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart'
    show MosqueRef;

/// The product/variant snapshot echoed inside an [EquipmentRequest]. Frozen at
/// creation: renaming a variant in the dashboard never rewrites a filed request
/// (delivery §3.1).
class RequestedItem extends Equatable {
  final int id;
  final String name;
  final String image;

  const RequestedItem({required this.id, this.name = '', this.image = ''});

  factory RequestedItem.fromJson(Map<String, dynamic> j) => RequestedItem(
    id: j['id'] as int? ?? 0,
    name: (j['name'] ?? '').toString(),
    image: (j['image'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [id, name, image];
}

/// Where a request sits in its lifecycle
/// (FLUTTER_NONLIVE_EQUIPMENT_ORDERING §حالات الطلب):
///
/// ```
/// UNDER_REVIEW → APPROVED → PAID → ASSIGNED_TO_TEAM → ASSIGNED → INSTALLED
///      └─(reject)→ REJECTED        └─(48h lapsed unpaid)→ CANCELLED
/// ```
enum EquipmentRequestStatus {
  underReview,
  approved,
  paid,
  assignedToTeam,
  assigned,
  installed,
  rejected,
  cancelled,
  unknown,
}

EquipmentRequestStatus equipmentStatusFrom(String raw) =>
    switch (raw.toUpperCase()) {
      'UNDER_REVIEW' => EquipmentRequestStatus.underReview,
      'APPROVED' => EquipmentRequestStatus.approved,
      'PAID' => EquipmentRequestStatus.paid,
      'ASSIGNED_TO_TEAM' => EquipmentRequestStatus.assignedToTeam,
      'ASSIGNED' => EquipmentRequestStatus.assigned,
      'INSTALLED' => EquipmentRequestStatus.installed,
      'REJECTED' => EquipmentRequestStatus.rejected,
      'CANCELLED' => EquipmentRequestStatus.cancelled,
      _ => EquipmentRequestStatus.unknown,
    };

/// A customer's catalogue order (`/equipment-requests/`).
class EquipmentRequest extends Equatable {
  final int id;
  final String code;
  final String reference;
  final MosqueRef? mosque;

  /// The product, and the picked combination when the product has axes.
  final RequestedItem? product;
  final RequestedItem? variant;

  final String unitPrice;
  final String dedicationName;
  final String dedicationStatus; // ALIVE | DECEASED | ''
  final EquipmentRequestStatus status;
  final String rejectionReason;

  /// End of the 48-hour window opened by approval. Only meaningful while the
  /// request is [EquipmentRequestStatus.approved].
  final DateTime? payDeadline;

  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? installedAt;

  /// The 10-digit code of the unit actually installed, once it is.
  final String installedCode;

  const EquipmentRequest({
    required this.id,
    this.code = '',
    this.reference = '',
    this.mosque,
    this.product,
    this.variant,
    this.unitPrice = '0',
    this.dedicationName = '',
    this.dedicationStatus = '',
    this.status = EquipmentRequestStatus.unknown,
    this.rejectionReason = '',
    this.payDeadline,
    this.paidAt,
    this.createdAt,
    this.approvedAt,
    this.installedAt,
    this.installedCode = '',
  });

  /// "المنتج — التنويع", or whichever half arrived. The variant name is
  /// composed by the server; nothing is assembled here.
  String get itemLabel => [
    product?.name ?? '',
    variant?.name ?? '',
  ].where((s) => s.isNotEmpty).join(' — ');

  /// Time left in the payment window, or null when there's no window running.
  /// Recomputed on read rather than counted down locally, so it survives the
  /// app being backgrounded.
  Duration? get timeLeftToPay {
    final deadline = payDeadline;
    if (deadline == null) return null;
    final left = deadline.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get windowClosed =>
      status == EquipmentRequestStatus.approved &&
      (timeLeftToPay ?? Duration.zero) <= Duration.zero;

  /// The pay button shows only inside an open window (§حالات الطلب). The server
  /// re-checks and 400s past the deadline, so this is a courtesy, not a gate.
  bool get canPay => status == EquipmentRequestStatus.approved && !windowClosed;

  bool get canCancel =>
      status == EquipmentRequestStatus.underReview ||
      status == EquipmentRequestStatus.approved;

  /// `ASSIGNED_TO_TEAM` and `ASSIGNED` are dispatch detail the customer doesn't
  /// need — both read as "being installed".
  bool get isInProgress =>
      status == EquipmentRequestStatus.assignedToTeam ||
      status == EquipmentRequestStatus.assigned;

  factory EquipmentRequest.fromJson(Map<String, dynamic> j) => EquipmentRequest(
    id: j['id'] as int? ?? 0,
    code: (j['code'] ?? '').toString(),
    reference: (j['reference'] ?? '').toString(),
    mosque: j['mosque'] is Map
        ? MosqueRef.fromJson(Map<String, dynamic>.from(j['mosque'] as Map))
        : null,
    product: j['product'] is Map
        ? RequestedItem.fromJson(Map<String, dynamic>.from(j['product'] as Map))
        : null,
    variant: j['variant'] is Map
        ? RequestedItem.fromJson(Map<String, dynamic>.from(j['variant'] as Map))
        : null,
    unitPrice: (j['unit_price'] ?? '0').toString(),
    dedicationName: (j['dedication_name'] ?? '').toString(),
    dedicationStatus: (j['dedication_status'] ?? '').toString().toUpperCase(),
    status: equipmentStatusFrom((j['status'] ?? '').toString()),
    rejectionReason: (j['rejection_reason'] ?? '').toString(),
    payDeadline: DateTime.tryParse((j['pay_deadline'] ?? '').toString()),
    paidAt: DateTime.tryParse((j['paid_at'] ?? '').toString()),
    createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
    approvedAt: DateTime.tryParse((j['approved_at'] ?? '').toString()),
    installedAt: DateTime.tryParse((j['installed_at'] ?? '').toString()),
    installedCode: (j['installed_code'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [id, status, payDeadline, installedCode];
}

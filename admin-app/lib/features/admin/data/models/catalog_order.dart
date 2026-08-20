import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/features/admin/data/models/mosque_need.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart' show StaffRef;

/// A customer's catalogue equipment order
/// (`GET /admin/equipment-requests-catalog/`).
///
/// **Not** the imam's equipment request (`/admin/equipment-requests/`): that one
/// is a mosque asking for a unit to be funded by donors; this one is a customer
/// buying a specific unit for a mosque of their choosing, which a manager
/// approves before any payment window opens
/// (FLUTTER_NONLIVE_EQUIPMENT_ORDERING §ثانياً).
class CatalogOrder extends Equatable {
  final int id;
  final String code;
  final String reference;
  final NeedMosque? mosque;

  /// The ordering customer, when the serializer includes them.
  final StaffRef? customer;

  /// The product plus the picked combination, already composed by the server
  /// ("مبرّد مياه ستيل — حوضان — عادي"). Falls back to the pre-unification
  /// `equipment_model.name` so an older server build still renders.
  final String modelName;
  final String unitPrice;

  final String dedicationName;
  final String dedicationStatus; // ALIVE | DECEASED | ''

  /// UNDER_REVIEW → APPROVED → PAID → ASSIGNED_TO_TEAM → ASSIGNED → INSTALLED,
  /// or REJECTED / CANCELLED.
  final String status;
  final String rejectionReason;

  final StaffRef? teamLeader;
  final StaffRef? assignedTo;

  final DateTime? payDeadline;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? installedAt;

  /// The unit code minted at installation (10 digits + QR + a year's warranty).
  final String installedCode;

  const CatalogOrder({
    required this.id,
    this.code = '',
    this.reference = '',
    this.mosque,
    this.customer,
    this.modelName = '',
    this.unitPrice = '0',
    this.dedicationName = '',
    this.dedicationStatus = '',
    this.status = '',
    this.rejectionReason = '',
    this.teamLeader,
    this.assignedTo,
    this.payDeadline,
    this.paidAt,
    this.createdAt,
    this.approvedAt,
    this.installedAt,
    this.installedCode = '',
  });

  static StaffRef? _ref(dynamic v) =>
      v is Map ? StaffRef.fromJson(Map<String, dynamic>.from(v)) : null;

  /// "المنتج — التنويع", or whatever half of it arrived. The composed variant
  /// name comes from the server; nothing is assembled from raw attributes here.
  static String _itemLabel(
    Map<String, dynamic> j,
    Map<String, dynamic> legacyModel,
  ) {
    String name(dynamic v) => v is Map ? (v['name'] ?? '').toString() : '';
    final parts = [
      name(j['product']),
      name(j['variant']),
    ].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' — ');
    return (legacyModel['name'] ?? '').toString();
  }

  factory CatalogOrder.fromJson(Map<String, dynamic> j) {
    final model = j['equipment_model'] is Map
        ? Map<String, dynamic>.from(j['equipment_model'] as Map)
        : const <String, dynamic>{};
    return CatalogOrder(
      id: j['id'] as int? ?? 0,
      code: (j['code'] ?? '').toString(),
      reference: (j['reference'] ?? '').toString(),
      mosque: j['mosque'] is Map
          ? NeedMosque.fromJson(Map<String, dynamic>.from(j['mosque'] as Map))
          : null,
      customer: _ref(j['customer']),
      modelName: _itemLabel(j, model),
      unitPrice: (j['unit_price'] ?? '0').toString(),
      dedicationName: (j['dedication_name'] ?? '').toString(),
      dedicationStatus: (j['dedication_status'] ?? '').toString().toUpperCase(),
      status: (j['status'] ?? '').toString().toUpperCase(),
      rejectionReason: (j['rejection_reason'] ?? '').toString(),
      teamLeader: _ref(j['team_leader']),
      assignedTo: _ref(j['assigned_to']),
      payDeadline: DateTime.tryParse((j['pay_deadline'] ?? '').toString()),
      paidAt: DateTime.tryParse((j['paid_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
      approvedAt: DateTime.tryParse((j['approved_at'] ?? '').toString()),
      installedAt: DateTime.tryParse((j['installed_at'] ?? '').toString()),
      installedCode: (j['installed_code'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, status, teamLeader, assignedTo];
}

/// The catalogue-order lifecycle, in order — used to build the status filter.
abstract final class CatalogOrderEnums {
  static const statuses = [
    'UNDER_REVIEW',
    'APPROVED',
    'PAID',
    'ASSIGNED_TO_TEAM',
    'ASSIGNED',
    'INSTALLED',
    'REJECTED',
    'CANCELLED',
  ];
}

/// A dispatch action on a catalogue order.
enum CatalogOrderAction {
  approve,
  reject,
  assignLeader,
  assignHandler,
  install,
}

/// Which actions are visible on a catalogue order, gating role capability and
/// status together (§ثانياً). Pure (no Flutter), mirroring the maintenance and
/// fulfilment matrices.
///
/// - [isManager]: regional or global manager — approves, rejects, and may drive
///   the whole assignment chain.
/// - [isAssignedLeader]: the team leader this order was handed to.
/// - [isAssignedHandler]: the handler assigned to install it.
///
/// Note the gap between `APPROVED` and `PAID`: nothing can be dispatched while
/// the customer's 48-hour payment window is still open, because there may be
/// nothing to install if they never pay.
Set<CatalogOrderAction> visibleCatalogOrderActions({
  required String status,
  required bool isManager,
  required bool isAssignedLeader,
  required bool isAssignedHandler,
}) {
  bool inStatus(List<String> allowed) => allowed.contains(status);
  return {
    if (isManager && inStatus(['UNDER_REVIEW'])) CatalogOrderAction.approve,
    if (isManager && inStatus(['UNDER_REVIEW'])) CatalogOrderAction.reject,
    if (isManager && inStatus(['PAID', 'ASSIGNED_TO_TEAM']))
      CatalogOrderAction.assignLeader,
    if ((isManager || isAssignedLeader) &&
        inStatus(['ASSIGNED_TO_TEAM', 'ASSIGNED']))
      CatalogOrderAction.assignHandler,
    if ((isManager || isAssignedLeader || isAssignedHandler) &&
        inStatus(['ASSIGNED']))
      CatalogOrderAction.install,
  };
}

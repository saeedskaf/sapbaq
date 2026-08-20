import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/core/utils/distance.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart' show StaffRef;

/// The unit as embedded in a maintenance case. Per the admin serializer,
/// [equipmentType] and [mosque] are plain name strings (not nested objects).
class CaseEquipment extends Equatable {
  final int id;
  final String code;
  final String equipmentType;
  final String mosque;

  const CaseEquipment({
    required this.id,
    this.code = '',
    this.equipmentType = '',
    this.mosque = '',
  });

  factory CaseEquipment.fromJson(Map<String, dynamic> j) => CaseEquipment(
    id: j['id'] as int? ?? 0,
    code: (j['code'] ?? '').toString(),
    equipmentType: (j['equipment_type'] ?? '').toString(),
    mosque: (j['mosque'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [id, code, equipmentType, mosque];
}

/// `GET /admin/maintenance/` (list) and `/{id}/` (detail) share one serializer.
/// The dispatch desk triages/approves/assigns; team leaders and members execute
/// and verify. Enum values are translated app-side (no `*_display` in admin).
class MaintenanceCase extends Equatable {
  final int id;
  final String reference;
  final String channel; // REP | QR_CUSTOMER | MANAGER
  final CaseEquipment? equipment;
  final StaffRef? reportedBy;
  final String reporterPhone;
  final String issueType;
  final String description;
  final String priority; // LOW | MEDIUM | HIGH | URGENT
  final String status; // internal (9 values)
  final String externalStatus; // SUBMITTED | IN_PROGRESS | RESOLVED | CANCELLED
  final String
  costPath; // UNSET | FREE_WARRANTY | MANUFACTURER_COMPRESSOR | CUSTOMER_PAID
  final String? price; // string money, only for CUSTOMER_PAID
  final bool routedToManufacturer;
  final String suggestedCostPath;
  final StaffRef? teamLeader;
  final StaffRef? teamMember;
  final String completionStatement;
  final List<String> photoUrls;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? assignedAt;
  final DateTime? resolvedAt;

  /// For a case merged as a duplicate: the id of the canonical case it folded
  /// into (null otherwise). Backend field `merged_into`.
  final int? mergedInto;

  /// Straight-line km from the caller to the equipment's mosque — present only
  /// when the list request carried the user's position (sorting doc §6).
  final double? distanceKm;

  /// Ready-to-open Google Maps link for that mosque (`mosque_maps_url`).
  final String? mosqueMapsUrl;

  const MaintenanceCase({
    required this.id,
    this.reference = '',
    this.channel = '',
    this.equipment,
    this.reportedBy,
    this.reporterPhone = '',
    this.issueType = '',
    this.description = '',
    this.priority = '',
    this.status = '',
    this.externalStatus = '',
    this.costPath = 'UNSET',
    this.price,
    this.routedToManufacturer = false,
    this.suggestedCostPath = '',
    this.teamLeader,
    this.teamMember,
    this.completionStatement = '',
    this.photoUrls = const [],
    this.createdAt,
    this.approvedAt,
    this.assignedAt,
    this.resolvedAt,
    this.mergedInto,
    this.distanceKm,
    this.mosqueMapsUrl,
  });

  bool get isQrCustomer => channel == 'QR_CUSTOMER';

  /// Raised directly by a regional/global manager — it skips triage and is
  /// born `APPROVED` (manager-direct doc §4.2).
  bool get isManagerChannel => channel == 'MANAGER';

  /// Approved but with no team leader yet: any team leader in the mosque's
  /// governorate may claim it (§4.3).
  bool get isClaimable => status == 'APPROVED' && teamLeader == null;

  static StaffRef? _ref(dynamic v) =>
      v is Map ? StaffRef.fromJson(Map<String, dynamic>.from(v)) : null;

  factory MaintenanceCase.fromJson(Map<String, dynamic> j) => MaintenanceCase(
    id: j['id'] as int? ?? 0,
    reference: (j['reference'] ?? '').toString(),
    channel: (j['channel'] ?? '').toString(),
    equipment: j['equipment'] is Map
        ? CaseEquipment.fromJson(
            Map<String, dynamic>.from(j['equipment'] as Map),
          )
        : null,
    reportedBy: _ref(j['reported_by']),
    reporterPhone: (j['reporter_phone'] ?? '').toString(),
    issueType: (j['issue_type'] ?? '').toString(),
    description: (j['description'] ?? '').toString(),
    priority: (j['priority'] ?? '').toString().toUpperCase(),
    status: (j['status'] ?? '').toString().toUpperCase(),
    externalStatus: (j['external_status'] ?? '').toString().toUpperCase(),
    costPath: (j['cost_path'] ?? 'UNSET').toString().toUpperCase(),
    price: j['price']?.toString(),
    routedToManufacturer: j['routed_to_manufacturer'] == true,
    suggestedCostPath: (j['suggested_cost_path'] ?? '')
        .toString()
        .toUpperCase(),
    teamLeader: _ref(j['team_leader']),
    teamMember: _ref(j['team_member']),
    completionStatement: (j['completion_statement'] ?? '').toString(),
    photoUrls:
        (j['photos'] as List?)
            ?.whereType<Map>()
            .map((e) => (e['image'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const [],
    createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
    approvedAt: DateTime.tryParse((j['approved_at'] ?? '').toString()),
    assignedAt: DateTime.tryParse((j['assigned_at'] ?? '').toString()),
    resolvedAt: DateTime.tryParse((j['resolved_at'] ?? '').toString()),
    mergedInto: j['merged_into'] as int?,
    distanceKm: parseDistanceKm(j['distance_km']),
    mosqueMapsUrl: (j['mosque_maps_url'] as String?)?.isNotEmpty == true
        ? j['mosque_maps_url'] as String
        : null,
  );

  /// Short human-friendly reference — the first UUID block, upper-cased.
  String get shortReference =>
      reference.isEmpty ? '' : reference.split('-').first.toUpperCase();

  @override
  List<Object?> get props => [
    id,
    status,
    costPath,
    priority,
    teamLeader,
    teamMember,
    distanceKm,
  ];
}

/// Enum value sets for the maintenance UI (labels are resolved via l10n).
class MaintenanceEnums {
  static const priorities = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];

  /// The full case lifecycle, in order — used to build the status filter.
  static const statuses = [
    'SUBMITTED',
    'ACKNOWLEDGED',
    'APPROVED',
    'ASSIGNED',
    'IN_PROGRESS',
    'COMPLETED',
    'RESOLVED',
    'DUPLICATE',
    'CANCELLED',
  ];

  /// Cost paths selectable at approval time (UNSET is the pre-approval state).
  static const approveCostPaths = [
    'FREE_WARRANTY',
    'MANUFACTURER_COMPRESSOR',
    'CUSTOMER_PAID',
  ];
}

/// A lifecycle action on a maintenance case.
enum MaintenanceAction {
  acknowledge,
  approve,
  claim,
  assignLeader,
  assignMember,
  complete,
  verify,
  setPriority,
  duplicate,
  cancel,
}

/// Which actions are visible on a case, gating role capability and case
/// [status] together per FLUTTER_OPERATIONS_CENTER §3–§4. Pure (no Flutter) so
/// the spec table can be asserted directly in tests.
///
/// - [isDesk]: the user triages (dispatch desk / global admin).
/// - [isLeader]: the user is the case's team leader (or the global admin).
/// - [canComplete]: the user is the case's team leader or assigned handler
///   (or the global admin).
/// - [isCustomerChannel]: the case came from a customer QR scan — the only
///   channel the backend lets us merge as a duplicate (a REP case → 400).
/// - [canClaim]: the user is a team leader and the case is still unassigned —
///   pass `user.canClaimMaintenance && case.teamLeader == null` (§4.3).
///   Optional so the pre-claim call sites (and their tests) keep compiling.
Set<MaintenanceAction> visibleMaintenanceActions({
  required String status,
  required bool isDesk,
  required bool isLeader,
  required bool canComplete,
  bool isCustomerChannel = false,
  bool canClaim = false,
}) {
  bool inStatus(List<String> allowed) => allowed.contains(status);
  return {
    if (isDesk && inStatus(['SUBMITTED'])) MaintenanceAction.acknowledge,
    if (isDesk && inStatus(['SUBMITTED', 'ACKNOWLEDGED']))
      MaintenanceAction.approve,
    // Pull vs push on the same status: the leader claims an unassigned case,
    // the desk hands one to a specific leader.
    if (canClaim && inStatus(['APPROVED'])) MaintenanceAction.claim,
    if (isDesk && inStatus(['APPROVED'])) MaintenanceAction.assignLeader,
    if (isLeader && inStatus(['ASSIGNED', 'IN_PROGRESS']))
      MaintenanceAction.assignMember,
    if (canComplete && inStatus(['ASSIGNED', 'IN_PROGRESS']))
      MaintenanceAction.complete,
    if (isLeader && inStatus(['COMPLETED'])) MaintenanceAction.verify,
    // Priority is a triage-only action — set before the case is dispatched.
    if (isDesk && inStatus(['SUBMITTED', 'ACKNOWLEDGED']))
      MaintenanceAction.setPriority,
    // Merge-duplicate is desk-only and backend-restricted to customer-channel
    // cases; kept to the pre-dispatch statuses to match the triage flow.
    if (isDesk && isCustomerChannel && inStatus(['SUBMITTED', 'ACKNOWLEDGED']))
      MaintenanceAction.duplicate,
    // Cancel stays through the active lifecycle, but not once work is done
    // (COMPLETED awaits verification) or the case is already terminal.
    if (isDesk &&
        inStatus([
          'SUBMITTED',
          'ACKNOWLEDGED',
          'APPROVED',
          'ASSIGNED',
          'IN_PROGRESS',
        ]))
      MaintenanceAction.cancel,
  };
}

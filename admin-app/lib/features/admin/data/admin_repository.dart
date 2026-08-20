import 'package:dio/dio.dart';
import 'package:sapbaq_admin/core/location/location_service.dart' show LatLng;
import 'package:sapbaq_admin/core/network/api_endpoints.dart';
import 'package:sapbaq_admin/core/network/api_guard.dart';
import 'package:sapbaq_admin/core/network/pagination.dart';
import 'package:sapbaq_admin/features/admin/data/models/activity_entry.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order_counts.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_product.dart';
import 'package:sapbaq_admin/features/admin/data/models/approval.dart';
import 'package:sapbaq_admin/features/admin/data/models/contribution.dart';
import 'package:sapbaq_admin/features/admin/data/models/catalog_order.dart';
import 'package:sapbaq_admin/features/admin/data/models/customer_lookup.dart';
import 'package:sapbaq_admin/features/admin/data/models/dashboard_summary.dart';
import 'package:sapbaq_admin/features/admin/data/models/equipment_catalog.dart';
import 'package:sapbaq_admin/features/admin/data/models/equipment_option.dart';
import 'package:sapbaq_admin/features/admin/data/models/escalation.dart';
import 'package:sapbaq_admin/features/admin/data/models/fulfilment_task.dart';
import 'package:sapbaq_admin/features/admin/data/models/maintenance_case.dart';
import 'package:sapbaq_admin/features/admin/data/models/ops_counts.dart';
import 'package:sapbaq_admin/features/admin/data/models/mosque_need.dart';
import 'package:sapbaq_admin/features/admin/data/models/workshop.dart';

/// Admin operations: browse orders, view detail, assign workshops, cancel, and
/// list workshops for the assignment flow. All methods throw
/// [ApiException] (Arabic, display-ready) on failure.
class AdminRepository {
  final Dio _dio;
  AdminRepository(this._dio);

  /// One page of the admin orders list with optional filters.
  ///
  /// [ordering] is omitted by default so the server default applies (FLUTTER_TASKS
  /// items 5+8: oldest-first for service handlers, `-status_updated_at` for
  /// managers). [bucket] `in_progress` selects orders with an ASSIGNED or
  /// IN_DELIVERY destination (item 10).
  Future<PaginatedResponse<AdminOrderSummary>> fetchOrders({
    int page = 1,
    String? status,
    bool? awaitingAssignment,
    String? bucket,
    int? mosque,
    int? workshop,
    String? search,
    String? code,
    String? ordering,
    LatLng? at,
  }) {
    return guardApi(() async {
      final params = <String, dynamic>{'page': page, ...?_origin(at)};
      if (ordering != null && ordering.isNotEmpty) {
        params['ordering'] = ordering;
      }
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (awaitingAssignment == true) params['awaiting_assignment'] = 'true';
      if (bucket != null && bucket.isNotEmpty) params['bucket'] = bucket;
      if (mosque != null) params['mosque'] = mosque;
      if (workshop != null) params['workshop'] = workshop;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (code != null && code.isNotEmpty) params['code'] = code;
      final res = await _dio.get(
        ApiEndpoints.adminOrders,
        queryParameters: params,
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        AdminOrderSummary.fromJson,
      );
    });
  }

  /// Per-tab counts for the orders list. Honors the same filters as
  /// [fetchOrders] except `status` (the counts are broken down by status).
  Future<AdminOrderCounts> fetchCounts({
    String? search,
    int? mosque,
    int? workshop,
  }) {
    return guardApi(() async {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (mosque != null) params['mosque'] = mosque;
      if (workshop != null) params['workshop'] = workshop;
      final res = await _dio.get(
        ApiEndpoints.adminOrdersCounts,
        queryParameters: params,
      );
      return AdminOrderCounts.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  Future<AdminOrderDetail> fetchOrder(int id) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.adminOrder(id));
      return AdminOrderDetail.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// Assign the whole order to a team leader (FLUTTER_TASKS T3). Every
  /// destination moves to `ASSIGNED_TO_TEAM` and the team leader is notified.
  /// Returns the refreshed order.
  Future<AdminOrderDetail> assignTeam(
    int orderId, {
    required int teamLeaderId,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.adminAssignTeam(orderId),
        data: {'team_leader_id': teamLeaderId},
      );
      return AdminOrderDetail.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// Team leader distributes a single destination to a handler/workshop (T3).
  /// [mosqueId] is required only for an unlocated MOST_NEEDED destination.
  Future<AdminOrderDetail> assignHandler(
    int orderId, {
    required int destinationId,
    required int driverId,
    int? mosqueId,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.adminAssignHandler(orderId),
        data: {
          'destination_id': destinationId,
          'driver_id': driverId,
          'mosque_id': ?mosqueId,
        },
      );
      return AdminOrderDetail.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// Team leader approves a destination's completion directly (T3), recording
  /// the handler who carried it out. [mosqueId] required only for an unlocated
  /// MOST_NEEDED destination. Marks the destination `DELIVERED`.
  Future<AdminOrderDetail> completeDestination(
    int orderId, {
    required int destinationId,
    required int driverId,
    int? mosqueId,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.adminCompleteOrder(orderId),
        data: {
          'destination_id': destinationId,
          'driver_id': driverId,
          'mosque_id': ?mosqueId,
        },
      );
      return AdminOrderDetail.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// Move a single destination to another workshop (§5). [mosqueId] is sent as
  /// `null` for an already-located destination. The backend rejects (400) a
  /// destination that's in delivery/finished or a no-op to the same workshop.
  Future<AdminOrderDetail> reassign(
    int orderId, {
    required int destinationId,
    required int driverId,
    int? mosqueId,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.adminReassignOrder(orderId),
        data: {
          'destination_id': destinationId,
          'driver_id': driverId,
          'mosque_id': mosqueId,
        },
      );
      return AdminOrderDetail.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  Future<AdminOrderDetail> cancel(int orderId, {required String reason}) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.adminCancelOrder(orderId),
        data: {'reason': reason},
      );
      return AdminOrderDetail.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// Workshops (handler accounts) for the distribute/complete picker. Returns a
  /// plain array (not paginated). For a team leader the backend scopes it to
  /// their own team members.
  Future<List<Workshop>> fetchWorkshops() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.adminWorkshops);
      return _parseStaffList(res.data);
    });
  }

  /// Team leaders for the manager's "assign to team leader" picker (T3). Same
  /// `{id, full_name, phone, active_load}` shape as workshops; the backend
  /// scopes the list to the manager's governorate.
  ///
  /// Orders only — for fulfilment tasks use [fetchTaskTeamLeaders], which scopes
  /// by the task's mosque governorate instead of the caller's.
  Future<List<Workshop>> fetchTeamLeaders() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.adminTeamLeaders);
      return _parseStaffList(res.data);
    });
  }

  /// Team leaders assignable to fulfilment [taskId] — scoped by the task's
  /// mosque governorate, so every name returned is accepted by the matching
  /// `assign-team-leader/` endpoint (backend note §1–2). Payload has no
  /// `active_load`. Empty `[]` means no eligible leader in that governorate.
  Future<List<Workshop>> fetchTaskTeamLeaders(int taskId) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminFulfilmentTaskAction(
          taskId,
          'assignable-team-leaders',
        ),
      );
      return _parseStaffList(res.data);
    });
  }

  /// Handlers assignable to fulfilment [taskId] — mosque-governorate scoped
  /// counterpart of [fetchWorkshops] for the task dispatch flow. No
  /// `active_load` in the payload (backend note §3).
  Future<List<Workshop>> fetchTaskHandlers(int taskId) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminFulfilmentTaskAction(taskId, 'assignable-handlers'),
      );
      return _parseStaffList(res.data);
    });
  }

  /// `lat/lng` query pair for a nearest-first sorted list, or nothing when the
  /// caller has no position. The server ignores out-of-range values, but we
  /// don't send them at all (sorting doc §1).
  Map<String, dynamic>? _origin(LatLng? at) {
    if (at == null) return null;
    if (at.lat.abs() > 90 || at.lng.abs() > 180) return null;
    return {'lat': at.lat, 'lng': at.lng};
  }

  List<Workshop> _parseStaffList(dynamic data) {
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? const []) : const []);
    return list
        .map((e) => Workshop.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// One page of approvals pending on the current user (§10).
  Future<PaginatedResponse<Approval>> fetchApprovals({int page = 1}) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminApprovals,
        queryParameters: {'page': page},
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        Approval.fromJson,
      );
    });
  }

  /// Approve a pending request — this also executes the deferred action (§10).
  Future<void> approveApproval(int id) {
    return guardApi(() async {
      await _dio.post(ApiEndpoints.adminApproveApproval(id));
    });
  }

  Future<void> rejectApproval(int id, {required String reason}) {
    return guardApi(() async {
      await _dio.post(
        ApiEndpoints.adminRejectApproval(id),
        data: {'reason': reason},
      );
    });
  }

  // --- Operations center ---

  /// The signed-in user's operations-center workload — one role-scoped call
  /// (`GET /admin/ops/counts/`) returning the "needs my action" count per queue
  /// (backend reply §2). The server applies the role's scope and per-queue
  /// actionable logic; queues the role can't act on come back 0.
  Future<OpsCounts> fetchOpsCounts() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.adminOpsCounts);
      return OpsCounts.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  // --- Water-flags moderation (dispatch desk) ---

  /// One page of mosque water flags, optionally filtered by status and calendar
  /// [month] (`YYYY-MM`). The regional manager is server-scoped to his
  /// governorate.
  Future<PaginatedResponse<AdminWaterFlag>> fetchWaterFlags({
    int page = 1,
    String? status,
    String? month,
  }) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminWaterFlags,
        queryParameters: {
          'page': page,
          if (status != null && status.isNotEmpty) 'status': status,
          if (month != null && month.isNotEmpty) 'month': month,
        },
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        AdminWaterFlag.fromJson,
      );
    });
  }

  /// Approve a water flag → it publishes to the customer "water" tab.
  Future<void> approveWaterFlag(int id) =>
      guardApi(() => _dio.post(ApiEndpoints.adminWaterFlagApprove(id)));

  Future<void> cancelWaterFlag(int id) =>
      guardApi(() => _dio.post(ApiEndpoints.adminWaterFlagCancel(id)));

  // --- Equipment-requests moderation (regional manager approves; desk cancels) ---

  /// One page of equipment requests. The server scopes the regional manager to
  /// his governorate automatically — do not send a governorate filter.
  Future<PaginatedResponse<AdminEquipmentRequest>> fetchEquipmentRequests({
    int page = 1,
    String? status,
    String? month,
  }) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminEquipmentRequests,
        queryParameters: {
          'page': page,
          if (status != null && status.isNotEmpty) 'status': status,
          if (month != null && month.isNotEmpty) 'month': month,
        },
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        AdminEquipmentRequest.fromJson,
      );
    });
  }

  // --- Manager direct provision (manager-direct doc §2–§4) ---
  // A regional/global manager raises a need for a mosque he picks; every one of
  // these lands already `APPROVED`, with no approval step in between.

  /// Raise a water flag for [mosqueId] — published for funding immediately.
  /// 400 when the mosque already has an open flag, 403 out of scope.
  Future<AdminWaterFlag> createWaterFlag(int mosqueId) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.adminWaterFlags,
        data: {'mosque_id': mosqueId},
      );
      return AdminWaterFlag.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// Raise an equipment request for [mosqueId]. The model is chosen up front
  /// (unlike the imam's request, approved later) because the request publishes
  /// to the marketplace at once and needs a target amount.
  Future<AdminEquipmentRequest> createEquipmentRequest({
    required int mosqueId,
    required int equipmentTypeId,
    required EquipmentPick pick,
    String? note,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.adminEquipmentRequests,
        data: {
          'mosque_id': mosqueId,
          'equipment_type_id': equipmentTypeId,
          'product_id': pick.product.id,
          'variant_id': ?pick.variant?.id,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return AdminEquipmentRequest.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// File a maintenance case directly on [equipmentId]. The manager fixes the
  /// cost path at creation (there's no approval step to fix it later), so
  /// [price] is required when [costPath] is `CUSTOMER_PAID` and [description]
  /// when [issueType] is `OTHER` — both enforced server-side too.
  ///
  /// Sent as multipart only when [photoPaths] is non-empty (up to 5), matching
  /// the imam's report endpoint.
  Future<MaintenanceCase> createMaintenanceCase({
    required int equipmentId,
    required String issueType,
    required String costPath,
    String? description,
    String? price,
    List<String> photoPaths = const [],
  }) {
    return guardApi(() async {
      final hasDescription = description != null && description.isNotEmpty;
      final needsPrice =
          costPath == 'CUSTOMER_PAID' && price != null && price.isNotEmpty;
      final fields = <String, dynamic>{
        'equipment_id': equipmentId,
        'issue_type': issueType,
        'cost_path': costPath,
        if (hasDescription) 'description': description,
        if (needsPrice) 'price': price,
      };
      final res = await _dio.post(
        ApiEndpoints.adminMaintenance,
        data: photoPaths.isEmpty
            ? fields
            : FormData.fromMap({
                ...fields,
                'photos': [
                  for (final path in photoPaths)
                    await MultipartFile.fromFile(path),
                ],
              }),
      );
      return MaintenanceCase.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// Equipment types for the direct request's first picker.
  Future<List<EquipmentTypeOption>> fetchEquipmentTypes() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.adminEquipmentTypes);
      return _parseList(res.data, EquipmentTypeOption.fromJson);
    });
  }

  /// Fundable products of [equipmentTypeId] with their axes and variants —
  /// each variant carries the price that becomes the request's target amount.
  Future<List<EquipmentOption>> fetchEquipmentOptions(int equipmentTypeId) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminEquipmentOptions,
        queryParameters: {'equipment_type_id': equipmentTypeId},
      );
      return _parseList(res.data, EquipmentOption.fromJson);
    });
  }

  /// The units installed at [mosqueId], for the direct maintenance report. An
  /// out-of-scope mosque comes back as an empty list (not an error).
  Future<List<MaintenanceEquipmentUnit>> fetchMaintenanceEquipment(
    int mosqueId,
  ) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminMaintenanceEquipment,
        queryParameters: {'mosque_id': mosqueId},
      );
      return _parseList(res.data, MaintenanceEquipmentUnit.fromJson);
    });
  }

  /// Parses either a bare array or a DRF `{results: []}` page — the manager
  /// lookups are documented as arrays, but the pagination shape is unconfirmed.
  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = data is List
        ? data
        : (data is Map ? (data['results'] as List? ?? const []) : const []);
    return items
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// The products available for [requestId]'s equipment type — the choices the
  /// approval picker offers, with their axes and variants.
  Future<List<EquipmentOption>> fetchRequestOptions(int requestId) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.marketplaceEquipmentOptions(requestId),
      );
      return _parseList(res.data, EquipmentOption.fromJson);
    });
  }

  /// Approve and publish for funding. The pick is mandatory: approving is what
  /// fixes the combination and freezes its price as the campaign's target
  /// amount (delivery §6.3). A variant that's no longer available comes back
  /// **409 `variant_unavailable`** with a message fit to show as-is.
  Future<void> approveEquipmentRequest(int id, {required EquipmentPick pick}) =>
      guardApi(
        () => _dio.post(
          ApiEndpoints.adminEquipmentRequestApprove(id),
          data: {
            'product_id': pick.product.id,
            'variant_id': ?pick.variant?.id,
          },
        ),
      );

  Future<void> rejectEquipmentRequest(int id, {required String reason}) =>
      guardApi(
        () => _dio.post(
          ApiEndpoints.adminEquipmentRequestReject(id),
          data: {'reason': reason},
        ),
      );

  Future<void> cancelEquipmentRequest(int id) =>
      guardApi(() => _dio.post(ApiEndpoints.adminEquipmentRequestCancel(id)));

  // --- Catalogue equipment orders (customer purchases) ---

  /// One page of catalogue orders, server-scoped to the caller (a regional
  /// manager sees his governorate, out-of-scope rows 404).
  Future<PaginatedResponse<CatalogOrder>> fetchCatalogOrders({
    int page = 1,
    String? status,
  }) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminCatalogOrders,
        queryParameters: {
          'page': page,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final data = res.data;
      if (data is List) {
        return PaginatedResponse(
          count: data.length,
          results: _parseList(data, CatalogOrder.fromJson),
        );
      }
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
        CatalogOrder.fromJson,
      );
    });
  }

  Future<CatalogOrder> fetchCatalogOrder(int id) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.adminCatalogOrder(id));
      return CatalogOrder.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  /// Run a catalogue-order action; every action returns the updated order.
  Future<CatalogOrder> _catalogAction(
    int id,
    String action, {
    Map<String, dynamic>? body,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.adminCatalogOrderAction(id, action),
        data: body,
      );
      return CatalogOrder.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  /// Team leaders assignable to catalogue order [id] — scoped by the **mosque's**
  /// governorate, not the caller's (backend answers §16), and backed by the same
  /// source the assignment endpoint validates against, so a name from this list
  /// is never rejected.
  Future<List<Workshop>> fetchCatalogTeamLeaders(int id) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminCatalogOrderAction(id, 'assignable-team-leaders'),
      );
      return _parseStaffList(res.data);
    });
  }

  /// Handlers assignable to catalogue order [id] — mosque-governorate scoped
  /// counterpart of [fetchCatalogTeamLeaders].
  Future<List<Workshop>> fetchCatalogHandlers(int id) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminCatalogOrderAction(id, 'assignable-handlers'),
      );
      return _parseStaffList(res.data);
    });
  }

  /// Approve the order — this opens the customer's 48-hour payment window.
  Future<CatalogOrder> approveCatalogOrder(int id) =>
      _catalogAction(id, 'approve');

  Future<CatalogOrder> rejectCatalogOrder(int id, {required String reason}) =>
      _catalogAction(id, 'reject', body: {'reason': reason});

  Future<CatalogOrder> assignCatalogTeamLeader(int id, int teamLeaderId) =>
      _catalogAction(
        id,
        'assign-team-leader',
        body: {'team_leader_id': teamLeaderId},
      );

  Future<CatalogOrder> assignCatalogHandler(int id, int handlerId) =>
      _catalogAction(id, 'assign-handler', body: {'handler_id': handlerId});

  /// Record the installation — this mints the real unit (code + QR + warranty)
  /// and fills the order's `installed_code`.
  Future<CatalogOrder> installCatalogOrder(int id) =>
      _catalogAction(id, 'install');

  // --- Maintenance triage & dispatch ---

  /// One page of maintenance cases, filtered by [status], [priority], calendar
  /// [month] (`YYYY-MM`) and a [search] over the equipment code (partial,
  /// case-insensitive). The server auto-scopes visibility by role (desk sees
  /// all, regional manager his governorate, team leader his team, member his
  /// own) and ignores invalid filter values silently.
  Future<PaginatedResponse<MaintenanceCase>> fetchMaintenanceCases({
    int page = 1,
    String? status,
    String? priority,
    String? month,
    String? search,
    LatLng? at,
  }) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminMaintenance,
        queryParameters: {
          'page': page,
          ...?_origin(at),
          if (status != null && status.isNotEmpty) 'status': status,
          if (priority != null && priority.isNotEmpty) 'priority': priority,
          if (month != null && month.isNotEmpty) 'month': month,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        MaintenanceCase.fromJson,
      );
    });
  }

  Future<MaintenanceCase> fetchMaintenanceCase(int id) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.adminMaintenanceCase(id));
      return MaintenanceCase.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// Run a case action; every action returns the full updated case.
  Future<MaintenanceCase> _caseAction(
    int id,
    String action, {
    Map<String, dynamic>? body,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.adminMaintenanceAction(id, action),
        data: body,
      );
      return MaintenanceCase.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  Future<MaintenanceCase> acknowledgeCase(int id) =>
      _caseAction(id, 'acknowledge');

  Future<MaintenanceCase> setCasePriority(int id, String priority) =>
      _caseAction(id, 'set-priority', body: {'priority': priority});

  /// Approve a case, fixing its cost path. [price] is required (and > 0) only
  /// when [costPath] is `CUSTOMER_PAID`; ignored otherwise.
  Future<MaintenanceCase> approveCase(
    int id, {
    required String costPath,
    String? price,
  }) => _caseAction(
    id,
    'approve',
    body: {
      'cost_path': costPath,
      if (costPath == 'CUSTOMER_PAID' && price != null && price.isNotEmpty)
        'price': price,
    },
  );

  Future<MaintenanceCase> assignCaseTeamLeader(int id, int teamLeaderId) =>
      _caseAction(
        id,
        'assign-team-leader',
        body: {'team_leader_id': teamLeaderId},
      );

  Future<MaintenanceCase> assignCaseMember(int id, int memberId) =>
      _caseAction(id, 'assign-member', body: {'member_id': memberId});

  /// Complete a case: multipart `statement` + at least one `photos` file
  /// (unified-dispatch doc §4-a — the server rejects a photo-less completion
  /// with 400; jpg/png/webp, ≤5MB each). The photos land in the COMPLETION
  /// stage of the case's photo strip.
  Future<MaintenanceCase> completeCase(
    int id, {
    required String statement,
    required List<String> photoPaths,
  }) {
    return guardApi(() async {
      final form = FormData.fromMap({
        'statement': statement,
        'photos': [
          for (final path in photoPaths) await MultipartFile.fromFile(path),
        ],
      });
      final res = await _dio.post(
        ApiEndpoints.adminMaintenanceAction(id, 'complete'),
        data: form,
      );
      return MaintenanceCase.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  Future<MaintenanceCase> verifyCase(int id) => _caseAction(id, 'verify');

  /// A team leader pulls an unassigned `APPROVED` case in his governorate onto
  /// his own team (manager-direct doc §4.3) — the counterpart of the desk
  /// pushing one with [assignCaseTeamLeader]. The case becomes `ASSIGNED` with
  /// the caller as its leader. 400 when it's already claimed or not `APPROVED`.
  Future<MaintenanceCase> claimCase(int id) => _caseAction(id, 'claim');

  /// Merge a customer-channel case into a canonical one (§3.1). [targetCaseId]
  /// is the canonical case's `id` (not its reference). The merged case becomes
  /// `DUPLICATE` with `merged_into` set. Backend rejects a REP case, a self-
  /// merge, or an out-of-scope target.
  Future<MaintenanceCase> duplicateCase(int id, {required int targetCaseId}) =>
      _caseAction(id, 'duplicate', body: {'target_case_id': targetCaseId});

  Future<MaintenanceCase> cancelCase(int id, {String? reason}) => _caseAction(
    id,
    'cancel',
    body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
  );

  // --- Marketplace contribution fulfilment ---

  /// One page of contributions, filtered by [status] (`PAID` by default on the
  /// server, or `all` for every status), [kind] (WATER/MAINTENANCE/EQUIPMENT)
  /// and calendar [month] (`YYYY-MM`). CONTRACT is always excluded; visibility
  /// is role-scoped by the server.
  Future<PaginatedResponse<AdminContribution>> fetchContributions({
    int page = 1,
    String? status,
    String? kind,
    String? month,
  }) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminContributions,
        queryParameters: {
          'page': page,
          if (status != null && status.isNotEmpty) 'status': status,
          if (kind != null && kind.isNotEmpty) 'kind': kind,
          if (month != null && month.isNotEmpty) 'month': month,
        },
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        AdminContribution.fromJson,
      );
    });
  }

  // --- Fulfilment-task dispatch (unified-dispatch doc §1) ---

  /// One page of fulfilment tasks, filtered by [status] (server default =
  /// the open ones). Visibility is role-scoped by the server.
  ///
  /// The doc doesn't pin the list shape, so both DRF pagination and a bare
  /// array are accepted (asked in the questions file).
  Future<PaginatedResponse<FulfilmentTask>> fetchFulfilmentTasks({
    int page = 1,
    String? status,
    LatLng? at,
  }) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminFulfilmentTasks,
        queryParameters: {
          'page': page,
          ...?_origin(at),
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final data = res.data;
      if (data is List) {
        return PaginatedResponse(
          count: data.length,
          results: [
            for (final e in data)
              FulfilmentTask.fromJson(Map<String, dynamic>.from(e as Map)),
          ],
        );
      }
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
        FulfilmentTask.fromJson,
      );
    });
  }

  /// Run a task action; every action returns the full updated task.
  Future<FulfilmentTask> _taskAction(int id, String action, {Object? body}) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.adminFulfilmentTaskAction(id, action),
        data: body,
      );
      return FulfilmentTask.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  Future<FulfilmentTask> assignTaskTeamLeader(int id, int teamLeaderId) =>
      _taskAction(
        id,
        'assign-team-leader',
        body: {'team_leader_id': teamLeaderId},
      );

  Future<FulfilmentTask> assignTaskHandler(int id, int handlerId) =>
      _taskAction(id, 'assign-handler', body: {'handler_id': handlerId});

  /// Settle a task: multipart `statement` + one `photo`, both required
  /// (jpg/png/webp, ≤5MB — content-verified server-side). A WATER task settles
  /// its whole flag's paid contributions and clears the flag; an EQUIPMENT
  /// task settles its request's contribution.
  Future<FulfilmentTask> fulfilTask(
    int id, {
    required String statement,
    required String photoPath,
  }) {
    return guardApi(() async {
      final form = FormData.fromMap({
        'statement': statement,
        'photo': await MultipartFile.fromFile(photoPath),
      });
      final res = await _dio.post(
        ApiEndpoints.adminFulfilmentTaskAction(id, 'fulfil'),
        data: form,
      );
      return FulfilmentTask.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// One page of escalations directed to the current user (§9).
  Future<PaginatedResponse<Escalation>> fetchEscalations({int page = 1}) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminEscalations,
        queryParameters: {'page': page},
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        Escalation.fromJson,
      );
    });
  }

  /// Raise an escalation (§9). With no [targetUserId]/[targetRole] the backend
  /// routes it to the current user's direct manager. [orderId] is optional and
  /// must be within the caller's visibility.
  Future<void> raiseEscalation({
    required String reason,
    int? orderId,
    int? targetUserId,
    String? targetRole,
  }) {
    return guardApi(() async {
      await _dio.post(
        ApiEndpoints.adminEscalations,
        data: {
          'reason': reason,
          'order_id': orderId,
          'target_user_id': targetUserId,
          'target_role': targetRole ?? '',
        },
      );
    });
  }

  Future<void> resolveEscalation(int id) {
    return guardApi(() async {
      await _dio.post(ApiEndpoints.adminResolveEscalation(id));
    });
  }

  /// One page of products visible to staff — available and suspended (§11).
  Future<PaginatedResponse<AdminProduct>> fetchProducts({
    int page = 1,
    String? search,
    bool? isAvailable,
    int? category,
  }) {
    return guardApi(() async {
      final params = <String, dynamic>{'page': page};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (isAvailable != null) params['is_available'] = isAvailable;
      if (category != null) params['category'] = category;
      final res = await _dio.get(
        ApiEndpoints.adminProducts,
        queryParameters: params,
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        AdminProduct.fromJson,
      );
    });
  }

  /// Temporarily suspend or re-enable a product's customer visibility (§11).
  /// [reason] is optional and recorded in the audit log.
  Future<void> setProductAvailability(
    int id, {
    required bool isAvailable,
    String? reason,
  }) {
    return guardApi(() async {
      await _dio.post(
        ApiEndpoints.adminProductAvailability(id),
        data: {
          'is_available': isAvailable,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
    });
  }

  /// The role-scoped daily summary (§6).
  Future<DashboardSummary> fetchDashboard() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.adminDashboard);
      return DashboardSummary.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// One page of the current user's activity feed (§8), newest first.
  Future<PaginatedResponse<ActivityEntry>> fetchActivity({int page = 1}) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.adminActivity,
        queryParameters: {'page': page},
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        ActivityEntry.fromJson,
      );
    });
  }

  /// Look up customers by phone and/or name (§7) — one of [phone]/[q] is
  /// required (the backend returns 400 otherwise). Each call is audited.
  Future<List<CustomerLookupResult>> lookupCustomers({
    String? phone,
    String? q,
    int? id,
  }) {
    return guardApi(() async {
      final params = <String, dynamic>{};
      if (phone != null && phone.isNotEmpty) params['phone'] = phone;
      if (q != null && q.isNotEmpty) params['q'] = q;
      if (id != null) params['id'] = id;
      final res = await _dio.get(
        ApiEndpoints.adminCustomerLookup,
        queryParameters: params,
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return (data['results'] as List<dynamic>? ?? const [])
          .map(
            (e) => CustomerLookupResult.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    });
  }

  // Mosque lookup for every picker lives in `MosqueLookupRepository` (the
  // public browse endpoints). A regional manager's picker is confined to his
  // own governorate client-side, which is why the role-scoped
  // `GET /admin/mosques/` — never delivered, see
  // BACKEND_ISSUE_ADMIN_MOSQUES_404_2026-08-01.md — is no longer on the path.
  // The create endpoints still enforce scope server-side.
}

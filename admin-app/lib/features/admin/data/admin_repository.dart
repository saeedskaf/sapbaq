import 'package:dio/dio.dart';
import 'package:sapbaq_admin/core/network/api_endpoints.dart';
import 'package:sapbaq_admin/core/network/api_guard.dart';
import 'package:sapbaq_admin/core/network/pagination.dart';
import 'package:sapbaq_admin/features/admin/data/models/activity_entry.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order_counts.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_product.dart';
import 'package:sapbaq_admin/features/admin/data/models/approval.dart';
import 'package:sapbaq_admin/features/admin/data/models/customer_lookup.dart';
import 'package:sapbaq_admin/features/admin/data/models/dashboard_summary.dart';
import 'package:sapbaq_admin/features/admin/data/models/escalation.dart';
import 'package:sapbaq_admin/features/admin/data/models/workshop.dart';
import 'package:sapbaq_admin/features/shared/data/models/mosque.dart';

/// Admin operations: browse orders, view detail, assign workshops, cancel, and
/// list workshops/mosques for the assignment flow. All methods throw
/// [ApiException] (Arabic, display-ready) on failure.
class AdminRepository {
  final Dio _dio;
  AdminRepository(this._dio);

  /// One page of the admin orders list with optional filters.
  Future<PaginatedResponse<AdminOrderSummary>> fetchOrders({
    int page = 1,
    String? status,
    bool? awaitingAssignment,
    int? mosque,
    int? workshop,
    String? search,
    String ordering = '-created_at',
  }) {
    return guardApi(() async {
      final params = <String, dynamic>{'page': page, 'ordering': ordering};
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (awaitingAssignment == true) params['awaiting_assignment'] = 'true';
      if (mosque != null) params['mosque'] = mosque;
      if (workshop != null) params['workshop'] = workshop;
      if (search != null && search.isNotEmpty) params['search'] = search;
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
  Future<List<Workshop>> fetchTeamLeaders() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.adminTeamLeaders);
      return _parseStaffList(res.data);
    });
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
  }) {
    return guardApi(() async {
      final params = <String, dynamic>{};
      if (phone != null && phone.isNotEmpty) params['phone'] = phone;
      if (q != null && q.isNotEmpty) params['q'] = q;
      final res = await _dio.get(
        ApiEndpoints.adminCustomerLookup,
        queryParameters: params,
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return (data['results'] as List<dynamic>? ?? const [])
          .map((e) => CustomerLookupResult.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    });
  }

  /// One page of mosques, used to pick a mosque for a MOST_NEEDED destination.
  Future<PaginatedResponse<Mosque>> fetchMosques({
    int page = 1,
    String? search,
  }) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.mosques,
        queryParameters: {
          'page': page,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        Mosque.fromJson,
      );
    });
  }
}

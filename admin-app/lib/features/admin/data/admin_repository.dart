import 'package:dio/dio.dart';
import 'package:sapbaq_admin/core/network/api_endpoints.dart';
import 'package:sapbaq_admin/core/network/api_guard.dart';
import 'package:sapbaq_admin/core/network/pagination.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
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

  Future<AdminOrderDetail> fetchOrder(int id) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.adminOrder(id));
      return AdminOrderDetail.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// Assign workshops to every pending destination in one call. Returns the
  /// updated order. The backend rejects (400) if not all pending destinations
  /// are covered, or a MOST_NEEDED destination is missing its `mosque_id`.
  Future<AdminOrderDetail> assign(int orderId, List<Assignment> assignments) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.adminAssignOrder(orderId),
        data: {'assignments': assignments.map((a) => a.toJson()).toList()},
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

  /// Workshops (DRIVER accounts) for the assignment picker. Returns a plain
  /// array (not paginated).
  Future<List<Workshop>> fetchWorkshops() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.adminWorkshops);
      final data = res.data;
      final list = data is List
          ? data
          : (data is Map ? (data['results'] as List? ?? const []) : const []);
      return list
          .map((e) => Workshop.fromJson(Map<String, dynamic>.from(e as Map)))
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

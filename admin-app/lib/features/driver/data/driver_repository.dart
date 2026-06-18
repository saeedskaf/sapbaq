import 'package:dio/dio.dart';
import 'package:sapbaq_admin/core/network/api_endpoints.dart';
import 'package:sapbaq_admin/core/network/api_guard.dart';
import 'package:sapbaq_admin/core/network/pagination.dart';
import 'package:sapbaq_admin/features/driver/data/models/driver_destination.dart';
import 'package:sapbaq_admin/features/shared/data/models/delivery_proof.dart';

/// Driver (workshop) operations: list/inspect assigned destinations, accept /
/// reject / start, and upload delivery proof. All methods throw [ApiException]
/// (Arabic, display-ready) on failure.
class DriverRepository {
  final Dio _dio;
  DriverRepository(this._dio);

  /// One page of destinations assigned to me, optionally filtered by status
  /// (ASSIGNED | IN_DELIVERY).
  Future<PaginatedResponse<DriverDestination>> fetchDestinations({
    int page = 1,
    String? status,
  }) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.driverDestinations,
        queryParameters: {
          'page': page,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        DriverDestination.fromJson,
      );
    });
  }

  Future<DriverDestination> fetchDestination(int id) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.driverDestination(id));
      return DriverDestination.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }

  /// Accept the assignment (sets `accepted_at` — required before starting).
  Future<void> accept(int id) {
    return guardApi(() => _dio.post(ApiEndpoints.driverAccept(id)));
  }

  /// Reject the assignment (returns it to PENDING for the admin to reassign).
  Future<void> reject(int id, {required String reason}) {
    return guardApi(
      () => _dio.post(ApiEndpoints.driverReject(id), data: {'reason': reason}),
    );
  }

  /// Start delivery — requires the destination to have been accepted first.
  Future<void> startDelivery(int id) {
    return guardApi(() => _dio.post(ApiEndpoints.driverStartDelivery(id)));
  }

  /// Upload one proof file (image or video) for a destination. The first upload
  /// flips the destination to DELIVERED. Call once per file.
  Future<DeliveryProof> uploadProof(
    int destinationId, {
    required String filePath,
    String note = '',
  }) {
    return guardApi(() async {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        if (note.isNotEmpty) 'note': note,
      });
      final res = await _dio.post(
        ApiEndpoints.uploadProof(destinationId),
        data: form,
      );
      return DeliveryProof.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    });
  }
}

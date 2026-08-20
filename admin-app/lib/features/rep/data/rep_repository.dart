import 'package:dio/dio.dart';
import 'package:sapbaq_admin/core/network/api_endpoints.dart';
import 'package:sapbaq_admin/core/network/api_guard.dart';
import 'package:sapbaq_admin/features/rep/data/models/rep_models.dart';

/// Mosque-representative capabilities (Bearer, role MOSQUE_REP): profile,
/// own-mosque equipment, and the three report actions. Auth/onboarding lives on
/// [AuthRepository] (it owns token storage and the session signal).
class RepRepository {
  final Dio _dio;
  RepRepository(this._dio);

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    final items = data is Map && data['results'] is List
        ? data['results'] as List
        : data as List? ?? const [];
    return items
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<RepProfile> me() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.repMe);
    return RepProfile.fromJson(Map<String, dynamic>.from(res.data as Map));
  });

  Future<List<RepEquipmentUnit>> equipment() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.repEquipment);
    return _list(res.data, RepEquipmentUnit.fromJson);
  });

  Future<List<RepMaintenanceReport>> maintenanceReports() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.repMaintenance);
    return _list(res.data, RepMaintenanceReport.fromJson);
  });

  /// File a maintenance report on one of the mosque's units. The server
  /// rejects a unit that already has an open case (surfaced as the Arabic
  /// message).
  ///
  /// When [photoPaths] is non-empty the request is sent as `multipart/form-data`
  /// with a repeated `photos` part (each ≤5MB, up to 5, jpg/png/webp — enforced
  /// server-side); otherwise a plain JSON body is sent (backward compatible).
  Future<void> reportMaintenance({
    required int equipmentId,
    required String issueType,
    String? description,
    List<String> photoPaths = const [],
  }) => guardApi(() async {
    final hasDescription = description != null && description.isNotEmpty;
    if (photoPaths.isEmpty) {
      await _dio.post(
        ApiEndpoints.repMaintenance,
        data: {
          'equipment_id': equipmentId,
          'issue_type': issueType,
          if (hasDescription) 'description': description,
        },
      );
      return;
    }
    final form = FormData.fromMap({
      'equipment_id': equipmentId,
      'issue_type': issueType,
      if (hasDescription) 'description': description,
      'photos': [
        for (final path in photoPaths) await MultipartFile.fromFile(path),
      ],
    });
    await _dio.post(ApiEndpoints.repMaintenance, data: form);
  });

  Future<List<RepWaterFlag>> waterFlags() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.repWaterFlag);
    return _list(res.data, RepWaterFlag.fromJson);
  });

  /// One-tap mosque-level water flag (no body). One active flag per mosque —
  /// the server blocks duplicates.
  Future<void> raiseWaterFlag() => guardApi(() async {
    await _dio.post(ApiEndpoints.repWaterFlag);
  });

  Future<List<RepEquipmentRequest>> equipmentRequests() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.repEquipmentRequest);
    return _list(res.data, RepEquipmentRequest.fromJson);
  });

  Future<void> requestEquipment({required int equipmentTypeId, String? note}) =>
      guardApi(() async {
        await _dio.post(
          ApiEndpoints.repEquipmentRequest,
          data: {
            'equipment_type_id': equipmentTypeId,
            if (note != null && note.isNotEmpty) 'note': note,
          },
        );
      });

  /// Equipment-type catalogue — proposed endpoint (Gap C); errors surface in
  /// the request form until the backend ships it.
  Future<List<RepEquipmentType>> equipmentTypes() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.repEquipmentTypes);
    return _list(res.data, RepEquipmentType.fromJson);
  });

  // Mosque lookup lives in `MosqueLookupRepository` — one browse path shared
  // by staff pickers and this (unauthenticated) registration wizard.
}

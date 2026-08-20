import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/features/equipment/data/models/equipment_models.dart';

/// The non-live equipment catalogue: browse (public), request for a mosque,
/// then — once a manager approves — pay inside a 48-hour window.
/// Contract: `FLUTTER_NONLIVE_EQUIPMENT_ORDERING.md`.
///
/// Payment itself is not here: it goes through `PaymentRepository` +
/// `PaymentGateway` like every other payment in the app.
class EquipmentRepository {
  final Dio _dio;
  EquipmentRepository(this._dio);

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    // The docs show bare arrays, but every other list in this API is paginated
    // — accept both so a later change doesn't break the screen.
    final items = data is Map && data['results'] is List
        ? data['results'] as List
        : data as List? ?? const [];
    return items
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  EquipmentRequest _request(dynamic data) =>
      EquipmentRequest.fromJson(Map<String, dynamic>.from(data as Map));

  /// File a request. Nothing is charged — it lands `UNDER_REVIEW` and waits for
  /// a manager. [dedicationName]/[dedicationStatus] are the optional engraving,
  /// sent together or not at all.
  ///
  /// The catalogue itself is gone: approval products come from `/products/`
  /// like everything else, and the server derives the equipment model from
  /// [variantId] (delivery §3.1).
  Future<EquipmentRequest> createRequest({
    required int mosqueId,
    required int productId,
    int? variantId,
    bool viaMostNeeded = false,
    String? dedicationName,
    String? dedicationStatus,
  }) => guardApi(() async {
    final hasName = dedicationName != null && dedicationName.isNotEmpty;
    final res = await _dio.post(
      ApiEndpoints.equipmentRequests,
      data: {
        'mosque_id': mosqueId,
        'product_id': productId,
        'variant_id': ?variantId,
        if (viaMostNeeded) 'via_most_needed': true,
        if (hasName) 'dedication_name': dedicationName,
        if (hasName && dedicationStatus != null && dedicationStatus.isNotEmpty)
          'dedication_status': dedicationStatus,
      },
    );
    return _request(res.data);
  });

  Future<List<EquipmentRequest>> myRequests() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.equipmentRequests);
    return _list(res.data, EquipmentRequest.fromJson);
  });

  /// One request by id — used when a push deep-links straight to it. Falls back
  /// to scanning the list if the backend hasn't shipped the detail route yet
  /// (asked in the questions file); a 404 there means "not ours", so rethrow.
  Future<EquipmentRequest> fetchRequest(int id) => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.equipmentRequest(id));
    return _request(res.data);
  });

  /// Withdraw a request before it's paid (`UNDER_REVIEW` or `APPROVED`).
  Future<void> cancelRequest(int id) => guardApi(() async {
    await _dio.post(ApiEndpoints.equipmentRequestCancel(id));
  });
}

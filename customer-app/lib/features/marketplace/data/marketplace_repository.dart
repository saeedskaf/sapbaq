import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';

/// Mosque-Needs marketplace data source. Feeds are public; contribute/cancel
/// and the payment handoff need Bearer. Contract:
/// `MOSQUE_NEEDS_BACKEND_DELIVERY.md`.
class MarketplaceRepository {
  final Dio _dio;
  MarketplaceRepository(this._dio);

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    // Accept a bare list or a paginated `{results: [...]}` envelope.
    final items = data is Map && data['results'] is List
        ? data['results'] as List
        : data as List;
    return items
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<MarketplaceSummary> summary() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.marketplaceSummary);
    return MarketplaceSummary.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  });

  Future<List<WaterListing>> water({int? mosqueId}) => guardApi(() async {
    final res = await _dio.get(
      ApiEndpoints.marketplaceWater,
      queryParameters: mosqueId != null ? {'mosque_id': mosqueId} : null,
    );
    return _list(res.data, WaterListing.fromJson);
  });

  Future<List<MaintenanceListing>> maintenance() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.marketplaceMaintenance);
    return _list(res.data, MaintenanceListing.fromJson);
  });

  Future<List<EquipmentListing>> equipment() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.marketplaceEquipment);
    return _list(res.data, EquipmentListing.fromJson);
  });

  ContributionResult _result(dynamic data) =>
      ContributionResult.fromJson(Map<String, dynamic>.from(data as Map));

  Future<ContributionResult> contributeWater({
    required int restockFlagId,
    required int packages,
  }) => guardApi(() async {
    final res = await _dio.post(
      ApiEndpoints.contributeWater,
      data: {'restock_flag_id': restockFlagId, 'packages': packages},
    );
    return _result(res.data);
  });

  Future<ContributionResult> contributeMaintenance({required int caseId}) =>
      guardApi(() async {
        final res = await _dio.post(
          ApiEndpoints.contributeMaintenance,
          data: {'case_id': caseId},
        );
        return _result(res.data);
      });

  Future<ContributionResult> contributeContract({required int equipmentId}) =>
      guardApi(() async {
        final res = await _dio.post(
          ApiEndpoints.contributeContract,
          data: {'equipment_id': equipmentId},
        );
        return _result(res.data);
      });

  /// Contribute a partial [amount] (a money string, up to 3 decimals) towards a
  /// campaign's goal. The model is fixed on the campaign, so there is nothing
  /// to choose here — crowdfunding doc §2.
  Future<ContributionResult> contributeEquipment({
    required int equipmentRequestId,
    required String amount,
  }) => guardApi(() async {
    final res = await _dio.post(
      ApiEndpoints.contributeEquipment,
      data: {'equipment_request_id': equipmentRequestId, 'amount': amount},
    );
    return _result(res.data);
  });

  // Paying a claimed contribution lives on `PaymentRepository` +
  // `PaymentGateway`, alongside every other payment — the gateway may host its
  // own page, which is more than a data source should own.

  Future<List<Contribution>> contributions() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.contributions);
    return _list(res.data, Contribution.fromJson);
  });

  /// One contribution plus its timeline. Fetched only when the detail screen
  /// opens — the list deliberately stays timeline-free.
  Future<ContributionDetail> contribution(int id) => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.contribution(id));
    return ContributionDetail.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  });

  Future<void> cancelContribution(int id) => guardApi(() async {
    await _dio.post(ApiEndpoints.contributionCancel(id));
  });
}

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/core/network/api_endpoints.dart';
import 'package:sapbaq_admin/core/network/api_guard.dart';
import 'package:sapbaq_admin/core/network/pagination.dart';

/// One governorate/area option with how many mosques sit under it.
class MosqueFacet extends Equatable {
  final String value;
  final int count;

  const MosqueFacet({required this.value, this.count = 0});

  /// The facets endpoint keys each row by its level (`governorate` / `area`).
  factory MosqueFacet.fromJson(Map<String, dynamic> j, String key) =>
      MosqueFacet(
        value: (j[key] ?? '').toString(),
        count: (j['count'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [value, count];
}

/// A mosque as offered by the picker. Deliberately its own model: the delivery
/// [Mosque] carries coordinates but no governorate, and [NeedMosque] only ever
/// arrives embedded in a need payload.
class PickableMosque extends Equatable {
  final int id;
  final String code;
  final String name;
  final String area;
  final String governorate;

  const PickableMosque({
    required this.id,
    this.code = '',
    this.name = '',
    this.area = '',
    this.governorate = '',
  });

  /// "area، governorate" — whichever parts the row carries.
  String get locationLine =>
      [area, governorate].where((s) => s.isNotEmpty).join('، ');

  factory PickableMosque.fromJson(Map<String, dynamic> j) => PickableMosque(
    id: j['id'] as int? ?? 0,
    code: (j['code'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    area: (j['area'] ?? '').toString(),
    governorate: (j['governorate'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [id, code, name, area, governorate];
}

/// The public mosque browse endpoints, behind one door for every mosque picker
/// in the app — staff, and the (unauthenticated) rep registration alike.
///
/// Both endpoints are public and unpaginated at the facet level, which is what
/// lets the same governorate → area → mosque walk serve a signed-in manager and
/// a self-registering imam without two data paths.
class MosqueLookupRepository {
  final Dio _dio;
  MosqueLookupRepository(this._dio);

  /// Governorate and area facets. [governorate] scopes the returned areas;
  /// without it, only the governorate list is meaningful.
  Future<(List<MosqueFacet> governorates, List<MosqueFacet> areas)> filters({
    String? governorate,
  }) => guardApi(() async {
    final res = await _dio.get(
      ApiEndpoints.mosquesFilters,
      queryParameters: {
        if (governorate != null && governorate.isNotEmpty)
          'governorate': governorate,
      },
    );
    final map = Map<String, dynamic>.from(res.data as Map);
    List<MosqueFacet> facets(dynamic list, String key) => list is List
        ? list
              .whereType<Map>()
              .map(
                (e) => MosqueFacet.fromJson(Map<String, dynamic>.from(e), key),
              )
              .where((f) => f.value.isNotEmpty)
              .toList()
        : const <MosqueFacet>[];
    return (
      facets(map['governorates'], 'governorate'),
      facets(map['areas'], 'area'),
    );
  });

  /// Mosques filtered by any combination of governorate, area and free text.
  Future<PaginatedResponse<PickableMosque>> mosques({
    int page = 1,
    String? search,
    String? governorate,
    String? area,
  }) => guardApi(() async {
    final res = await _dio.get(
      ApiEndpoints.mosques,
      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (governorate != null && governorate.isNotEmpty)
          'governorate': governorate,
        if (area != null && area.isNotEmpty) 'area': area,
      },
    );
    final data = res.data;
    // Tolerates a bare array as one full page — the rep flow's list arrives
    // that way today.
    if (data is List) {
      return PaginatedResponse(
        count: data.length,
        results: data
            .whereType<Map>()
            .map((e) => PickableMosque.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }
    return PaginatedResponse.fromJson(
      Map<String, dynamic>.from(data as Map),
      PickableMosque.fromJson,
    );
  });
}

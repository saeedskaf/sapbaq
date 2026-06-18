import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/pagination.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/mosques/data/models/mosque_filters.dart';

class MosquesRepository {
  final Dio _dio;
  MosquesRepository(this._dio);

  /// One page of the mosque list (20/page). The list view paginates via [page]
  /// and `PaginatedResponse.hasMore`. Filters (search + governorate/area/block)
  /// compose freely.
  Future<PaginatedResponse<Mosque>> fetchMosques({
    int page = 1,
    String? search,
    String? governorate,
    String? area,
    String? block,
  }) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.mosques,
        queryParameters: {
          'page': page,
          if (search != null && search.isNotEmpty) 'search': search,
          if (governorate != null && governorate.isNotEmpty)
            'governorate': governorate,
          if (area != null && area.isNotEmpty) 'area': area,
          if (block != null && block.isNotEmpty) 'block': block,
        },
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        Mosque.fromJson,
      );
    });
  }

  /// Cascading filter facets. Pass [governorate] to scope areas/blocks, and
  /// also [area] to scope blocks further.
  Future<MosqueFilters> fetchFilters({String? governorate, String? area}) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.mosquesFilters,
        queryParameters: {
          if (governorate != null && governorate.isNotEmpty)
            'governorate': governorate,
          if (area != null && area.isNotEmpty) 'area': area,
        },
      );
      return MosqueFilters.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  /// All mosques with coordinates, for the map (endpoint: /mosques/map/).
  /// The backend returns GeoJSON: `{type, count, features: [...]}`.
  Future<List<Mosque>> fetchMosquesForMap() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.mosquesMap);
      final data = res.data;
      if (data is Map && data['features'] is List) {
        return (data['features'] as List)
            .map(
              (e) =>
                  Mosque.fromGeoJsonFeature(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
      // Fallbacks (plain list or paginated), just in case.
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .map((e) => Mosque.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (data is List) {
        return data
            .map((e) => Mosque.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return const <Mosque>[];
    });
  }

  Future<Mosque> fetchMosque(int id) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.mosque(id));
      return Mosque.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  // --- Favorites (A.3) ---

  /// The user's favorite mosques (same item shape as the list).
  Future<List<Mosque>> fetchFavorites() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.mosqueFavorites);
      final data = res.data;
      if (data is Map && data['results'] is List) {
        return PaginatedResponse.fromJson(
          Map<String, dynamic>.from(data),
          Mosque.fromJson,
        ).results;
      }
      if (data is List) {
        return data
            .map((e) => Mosque.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return const <Mosque>[];
    });
  }

  /// Add to favorites (idempotent server-side).
  Future<void> addFavorite(int mosqueId) {
    return guardApi(() async {
      await _dio.post(
        ApiEndpoints.mosqueFavorites,
        data: {'mosque_id': mosqueId},
      );
    });
  }

  Future<void> removeFavorite(int mosqueId) {
    return guardApi(() async {
      await _dio.delete(ApiEndpoints.mosqueFavorite(mosqueId));
    });
  }
}

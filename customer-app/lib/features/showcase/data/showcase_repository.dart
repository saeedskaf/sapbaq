import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/features/showcase/data/models/showcase_item.dart';

class ShowcaseRepository {
  final Dio _dio;
  ShowcaseRepository(this._dio);

  /// Public media gallery (server-sorted). Returns a plain list; tolerates a
  /// paginated envelope just in case. [type] optionally filters IMAGE/VIDEO.
  Future<List<ShowcaseItem>> fetchShowcase({String? type}) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.showcase,
        queryParameters: type != null ? {'type': type} : null,
      );
      final data = res.data;
      final list = data is List
          ? data
          : (data is Map && data['results'] is List
                ? data['results'] as List
                : const []);
      return list
          .map((e) => ShowcaseItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }
}

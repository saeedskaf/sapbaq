import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/features/banners/data/models/banner.dart';

class BannersRepository {
  final Dio _dio;
  BannersRepository(this._dio);

  /// Active banners (backend filters by schedule). Optionally scoped to a [type].
  /// Returns a plain list; tolerates a paginated envelope just in case.
  Future<List<PromoBanner>> fetchBanners({BannerType? type}) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.banners,
        queryParameters: type != null ? {'type': type.name} : null,
      );
      final data = res.data;
      final list = data is List
          ? data
          : (data is Map && data['results'] is List
                ? data['results'] as List
                : const []);
      return list
          .map((e) => PromoBanner.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }
}

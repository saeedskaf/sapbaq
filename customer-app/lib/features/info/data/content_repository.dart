import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/features/info/data/models/content_page.dart';

/// Public CMS pages: privacy · terms · about · faq. Bilingual (the active
/// `Accept-Language` selects the language of the returned text).
class ContentRepository {
  final Dio _dio;
  ContentRepository(this._dio);

  Future<ContentPage> fetchContent(String slug) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.content(slug));
      return ContentPage.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }
}

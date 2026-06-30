import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/features/info/data/models/contact_info.dart';
import 'package:sapbaq/features/info/data/models/content_page.dart';

/// Public CMS pages: privacy · terms · about · faq, plus the support-contact
/// details. Bilingual (the active `Accept-Language` selects the language).
class ContentRepository {
  final Dio _dio;
  ContentRepository(this._dio);

  Future<ContentPage> fetchContent(String slug) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.content(slug));
      return ContentPage.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  /// Support-contact details for the "Contact us" screen.
  Future<ContactInfo> fetchContact() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.contact);
      return ContactInfo.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }
}

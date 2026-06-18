import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/features/gifts/data/models/gift.dart';
import 'package:sapbaq/features/gifts/data/models/gift_category.dart';

class GiftsRepository {
  final Dio _dio;
  GiftsRepository(this._dio);

  /// Gift categories (الزوجة، الوالد...) — the first step of the gift flow.
  Future<List<GiftCategory>> fetchCategories() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.giftCategories);
      return _listOf(res.data)
          .map((e) => GiftCategory.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  /// Templates belonging to a single category.
  Future<List<GiftTemplate>> fetchCategoryTemplates(int categoryId) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.giftCategoryTemplates(categoryId),
      );
      return _listOf(res.data)
          .map((e) => GiftTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  /// These endpoints return a plain list, but tolerate a paginated envelope too.
  List _listOf(dynamic data) => data is List
      ? data
      : (data is Map && data['results'] is List
            ? data['results'] as List
            : const []);

  /// The gift attached to the cart, or null if none (404).
  Future<Gift?> getGift() async {
    try {
      final res = await _dio.get(ApiEndpoints.cartGift);
      return Gift.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioException(e);
    }
  }

  /// Attach (or replace) the cart's gift. `relation_type` is inferred server-side
  /// from the template's category, so it's no longer sent.
  Future<Gift> attachGift({
    required String dedicatedToName,
    required String senderName,
    required String notifyPhone,
    required int templateId,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.cartGift,
        data: {
          'dedicated_to_name': dedicatedToName,
          'sender_name': senderName,
          'notify_phone': notifyPhone,
          'template_id': templateId,
        },
      );
      return Gift.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  Future<void> removeGift() {
    return guardApi(() async {
      await _dio.delete(ApiEndpoints.cartGift);
    });
  }
}

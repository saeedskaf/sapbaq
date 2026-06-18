import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/network/pagination.dart';
import 'package:sapbaq/features/orders/data/models/delivery_proof.dart';
import 'package:sapbaq/features/orders/data/models/order.dart';
import 'package:sapbaq/features/orders/data/models/review.dart';

class OrdersRepository {
  final Dio _dio;
  OrdersRepository(this._dio);

  /// One page of the customer's orders (newest first). The list view paginates
  /// via [page] + `PaginatedResponse.hasMore` so the full history is reachable.
  Future<PaginatedResponse<Order>> fetchOrders({int page = 1}) {
    return guardApi(() async {
      final res = await _dio.get(
        ApiEndpoints.orders,
        queryParameters: {'page': page},
      );
      return PaginatedResponse.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        Order.fromJson,
      );
    });
  }

  Future<Order> fetchOrder(int id) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.order(id));
      return Order.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  /// Cancel an order (customer can cancel only PENDING). Returns updated order.
  Future<Order> cancelOrder(int id, {String? reason}) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.cancelOrder(id),
        data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      );
      return Order.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  /// Existing review for an order, or null if not reviewed yet (404).
  Future<Review?> getReview(int id) async {
    try {
      final res = await _dio.get(ApiEndpoints.orderReview(id));
      return Review.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioException(e);
    }
  }

  /// Delivery proofs for an order (photos/videos uploaded on delivery). Returns
  /// a flat list; the UI groups by `destinationId`. Empty until something ships.
  Future<List<DeliveryProof>> fetchProofs(int orderId) {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.orderProofs(orderId));
      final data = res.data;
      final list = data is List
          ? data
          : (data is Map && data['results'] is List
                ? data['results'] as List
                : const []);
      return list
          .map((e) => DeliveryProof.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  Future<Review> submitReview(int id, {required int rating, String? comment}) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.orderReview(id),
        data: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      return Review.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }
}

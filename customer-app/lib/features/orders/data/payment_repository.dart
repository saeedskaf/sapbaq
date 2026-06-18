import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';

class PaymentRepository {
  final Dio _dio;
  PaymentRepository(this._dio);

  /// Dev flow: initiate then confirm the (mock) payment for an order.
  /// In production this is replaced by a payment gateway + webhook.
  Future<void> payOrder(int orderId) {
    return guardApi(() async {
      final init = await _dio.post(
        ApiEndpoints.initiatePayment,
        data: {'order_id': orderId},
      );
      final paymentId =
          Map<String, dynamic>.from(init.data as Map)['id'] as int;
      await _dio.post(
        ApiEndpoints.confirmPayment,
        data: {'payment_id': paymentId},
      );
    });
  }
}

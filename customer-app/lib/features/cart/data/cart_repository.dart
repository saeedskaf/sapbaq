import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/features/cart/data/models/cart.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';

class CartRepository {
  final Dio _dio;
  CartRepository(this._dio);

  Future<Cart> getCart() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.cart);
      return Cart.fromJson(Map<String, dynamic>.from(res.data as Map));
    });
  }

  Future<Cart> addItem({
    required int productId,
    required int quantity,
    required DonationDestination destination,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.cartItems,
        data: {
          'product_id': productId,
          'quantity': quantity,
          ...destination.toItemParams(),
        },
      );
      return _cartFrom(res);
    });
  }

  Future<Cart> updateQuantity(int itemId, int quantity) {
    return guardApi(() async {
      final res = await _dio.patch(
        ApiEndpoints.cartItem(itemId),
        data: {'quantity': quantity},
      );
      return _cartFrom(res);
    });
  }

  Future<Cart> removeItem(int itemId) {
    return guardApi(() async {
      final res = await _dio.delete(ApiEndpoints.cartItem(itemId));
      return _cartFrom(res);
    });
  }

  Future<Cart> removeGroup(int groupId) {
    return guardApi(() async {
      final res = await _dio.delete(ApiEndpoints.cartGroup(groupId));
      return _cartFrom(res);
    });
  }

  Future<Cart> clear() {
    return guardApi(() async {
      final res = await _dio.delete(ApiEndpoints.cart);
      return _cartFrom(res);
    });
  }

  Future<Cart> applyCoupon(String code) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.applyCoupon,
        data: {'code': code},
      );
      return _cartFrom(res);
    });
  }

  Future<Cart> removeCoupon() {
    return guardApi(() async {
      final res = await _dio.delete(ApiEndpoints.cartCoupon);
      return _cartFrom(res);
    });
  }

  /// Checkout the whole cart (destinations come from the groups). Returns the
  /// created order id.
  Future<int> checkout({String? notes}) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.checkout,
        data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
      );
      return Map<String, dynamic>.from(res.data as Map)['id'] as int;
    });
  }

  /// Some mutating endpoints return the updated cart; others return 204.
  /// Parse the body if present, otherwise re-fetch.
  Future<Cart> _cartFrom(Response<dynamic> res) async {
    final data = res.data;
    if (data is Map) return Cart.fromJson(Map<String, dynamic>.from(data));
    return getCart();
  }
}

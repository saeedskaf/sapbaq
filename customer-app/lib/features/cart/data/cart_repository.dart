import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/features/cart/data/models/cart.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';

/// What one checkout produced: the order to pay, and exactly which carts that
/// single amount covers.
///
/// [cartIds] is why this isn't just an int. The server decides what "all my
/// carts" means at the moment of checkout, so its answer — not our list — is
/// what the payment covers, what to say the customer is paying for, and what
/// should be gone once it lands.
class CheckoutResult {
  final int orderId;
  final List<int> cartIds;

  const CheckoutResult({required this.orderId, required this.cartIds});

  /// How many mosques this one payment is for.
  int get destinationCount => cartIds.length;
}

/// Multiple destination-bound carts. Every mutation returns the full, updated
/// carts list (same shape as `GET /carts/`). Contract: CARTS_BACKEND_DELIVERY.md.
class CartRepository {
  final Dio _dio;
  CartRepository(this._dio);

  Future<List<DonationCart>> getCarts() {
    return guardApi(() async {
      final res = await _dio.get(ApiEndpoints.carts);
      return DonationCart.listFrom(res.data);
    });
  }

  /// Adds an item to its destination's cart (find-or-create server-side).
  ///
  /// [variantId] is required server-side for a product with variants and must
  /// be omitted otherwise (PRODUCT_VARIANTS_BACKEND_DELIVERY §3.1).
  /// [dedicationName]/[dedicationStatus] are sent for dedication products (e.g.
  /// sabeel coolers); they're required server-side when the product's category
  /// enables dedication, and ignored for ordinary products.
  Future<List<DonationCart>> addItem({
    required int productId,
    required int quantity,
    required DonationDestination destination,
    int? variantId,
    String? dedicationName,
    String? dedicationStatus,
  }) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.cartsItems,
        data: {
          'product_id': productId,
          'variant_id': ?variantId,
          'quantity': quantity,
          ...destination.toItemParams(),
          if (dedicationName != null && dedicationName.isNotEmpty)
            'dedication_name': dedicationName,
          if (dedicationStatus != null && dedicationStatus.isNotEmpty)
            'dedication_status': dedicationStatus,
        },
      );
      return DonationCart.listFrom(res.data);
    });
  }

  Future<List<DonationCart>> updateQuantity(int itemId, int quantity) {
    return guardApi(() async {
      final res = await _dio.patch(
        ApiEndpoints.cartsItem(itemId),
        data: {'quantity': quantity},
      );
      return DonationCart.listFrom(res.data);
    });
  }

  Future<List<DonationCart>> removeItem(int itemId) {
    return guardApi(() async {
      final res = await _dio.delete(ApiEndpoints.cartsItem(itemId));
      return DonationCart.listFrom(res.data);
    });
  }

  Future<List<DonationCart>> deleteCart(int cartId) {
    return guardApi(() async {
      final res = await _dio.delete(ApiEndpoints.cartById(cartId));
      return DonationCart.listFrom(res.data);
    });
  }

  /// Re-bind a cart to another destination (merges if the target already has a
  /// cart).
  Future<List<DonationCart>> changeDestination(
    int cartId,
    DonationDestination destination,
  ) {
    return guardApi(() async {
      final res = await _dio.patch(
        ApiEndpoints.cartById(cartId),
        data: destination.toItemParams(),
      );
      return DonationCart.listFrom(res.data);
    });
  }

  Future<List<DonationCart>> applyCoupon(int cartId, String code) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.cartApplyCoupon(cartId),
        data: {'code': code},
      );
      return DonationCart.listFrom(res.data);
    });
  }

  Future<List<DonationCart>> removeCoupon(int cartId) {
    return guardApi(() async {
      final res = await _dio.delete(ApiEndpoints.cartCoupon(cartId));
      return DonationCart.listFrom(res.data);
    });
  }

  /// Saves this cart's gift. These three fields are everything the server
  /// takes: the card design is chosen server-side from the one approved
  /// template (GIFT_SIMPLIFIED_2026-08-04 §3).
  ///
  /// The shipped contract documents this as POST (CARTS_BACKEND_DELIVERY.md
  /// §2.3) while the newer note writes it as PUT on the same path, so retry
  /// once on 405 rather than betting on either routing.
  Future<List<DonationCart>> attachGift(
    int cartId, {
    required String dedicatedToName,
    required String senderName,
    required String notifyPhone,
  }) {
    return guardApi(() async {
      final path = ApiEndpoints.cartGift(cartId);
      final body = {
        'dedicated_to_name': dedicatedToName,
        'sender_name': senderName,
        'notify_phone': notifyPhone,
      };
      Response<dynamic> res;
      try {
        res = await _dio.post(path, data: body);
      } on DioException catch (e) {
        if (e.response?.statusCode != 405) rethrow;
        res = await _dio.put(path, data: body);
      }
      return DonationCart.listFrom(res.data);
    });
  }

  Future<List<DonationCart>> removeGift(int cartId) {
    return guardApi(() async {
      final res = await _dio.delete(ApiEndpoints.cartGift(cartId));
      return DonationCart.listFrom(res.data);
    });
  }

  /// Checks carts out into ONE order across all their destinations — one
  /// amount, one payment (FLUTTER_COMBINED_CHECKOUT §2).
  ///
  /// [cartIds] null or empty means every open cart, which is what the pay
  /// button wants and what the contract asks us to send (nothing at all, rather
  /// than a list we assembled and could get wrong). Pass a single id to pay one
  /// mosque on its own.
  ///
  /// Throws with `multiple_coupons_in_checkout` / `multiple_gifts_in_checkout`
  /// when the carts disagree about a coupon or a gift card; `details.cart_ids`
  /// on the exception names the ones to fix (§5).
  Future<CheckoutResult> checkout({List<int>? cartIds, String? notes}) {
    return guardApi(() async {
      final res = await _dio.post(
        ApiEndpoints.cartsCheckout,
        data: {
          if (cartIds != null && cartIds.isNotEmpty) 'cart_ids': cartIds,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      return CheckoutResult(
        orderId: body['order_id'] as int,
        cartIds: [
          for (final id in body['cart_ids'] as List<dynamic>? ?? const [])
            id as int,
        ],
      );
    });
  }
}

import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/api_guard.dart';
import 'package:sapbaq/core/payments/payment_session.dart';
import 'package:sapbaq/features/orders/data/models/payment.dart';

/// The two halves of every payment (FLUTTER_PAYMENTS_MYFATOORAH): **initiate**
/// creates the attempt and may hand back a hosted page, **confirm** settles it.
///
/// This class only speaks HTTP; the browser hop between the two lives in
/// `PaymentGateway`, which callers should use instead of driving these directly
/// — confirming before the customer has actually paid just yields FAILED.
class PaymentRepository {
  final Dio _dio;
  PaymentRepository(this._dio);

  Payment _payment(dynamic data) =>
      Payment.fromJson(Map<String, dynamic>.from(data as Map));

  /// Start paying a consumables order (a checked-out cart).
  Future<Payment> initiateOrderPayment(int orderId) => guardApi(() async {
    final res = await _dio.post(
      ApiEndpoints.initiatePayment,
      data: {'order_id': orderId},
    );
    return _payment(res.data);
  });

  /// Start paying a claimed marketplace contribution (live mosque needs).
  /// Throws `ApiException(code: 'hold_expired')` once the claim's hold lapses.
  Future<Payment> initiateContributionPayment(int contributionId) =>
      guardApi(() async {
        final res = await _dio.post(
          ApiEndpoints.initiatePayment,
          data: {'contribution_id': contributionId},
        );
        return _payment(res.data);
      });

  /// Start paying an approved equipment request. It has its own endpoint rather
  /// than the shared one because it also enforces the 48-hour approval window
  /// (FLUTTER_NONLIVE_EQUIPMENT_ORDERING §4) — 400 outside it.
  Future<Payment> initiateEquipmentPayment(int requestId) => guardApi(() async {
    final res = await _dio.post(ApiEndpoints.equipmentRequestPay(requestId));
    return _payment(res.data);
  });

  /// Settle the attempt. The server re-queries the gateway rather than trusting
  /// the app's return, so this is safe to call even when the customer closed the
  /// payment page — and safe to call twice.
  Future<Payment> confirm(int paymentId) => guardApi(() async {
    final res = await _dio.post(
      ApiEndpoints.confirmPayment,
      data: {'payment_id': paymentId},
    );
    return _payment(res.data);
  });

  // ── Embedded checkout ────────────────────────────────────────────────────
  //
  // `session` → card entered in-app → `execute` → `confirm`. The split matters:
  // no gateway invoice exists until `execute`, so a customer who opens the
  // sheet and thinks better of it leaves nothing behind.

  /// Open a session for whichever of the three targets is given. Exactly one
  /// must be non-null.
  ///
  /// [saveCard] belongs here rather than on [execute] because MyFatoorah ties
  /// tokenization to the session — the choice has to be known before the card
  /// fields are drawn.
  Future<PaymentSession> openSession({
    int? orderId,
    int? contributionId,
    int? equipmentRequestId,
    bool saveCard = false,
  }) => guardApi(() async {
    assert(
      [orderId, contributionId, equipmentRequestId].nonNulls.length == 1,
      'a session pays exactly one thing',
    );
    final body = <String, dynamic>{'save_card': saveCard};
    if (orderId != null) body['order_id'] = orderId;
    if (contributionId != null) body['contribution_id'] = contributionId;
    if (equipmentRequestId != null) {
      body['equipment_request_id'] = equipmentRequestId;
    }
    final res = await _dio.post(ApiEndpoints.paymentSession, data: body);
    return PaymentSession.fromJson(Map<String, dynamic>.from(res.data as Map));
  });

  /// Charge the session. The server orders the charge and reads the amount from
  /// its own record, so nothing here can change what is taken.
  ///
  /// A saved card is *not* named here: it is bound to the session inside the
  /// app before this call, so this request looks identical either way. Sending
  /// a `card_token` earns a `card_token_unsupported` 400 by design.
  Future<PaymentExecution> execute({
    required int paymentId,
    required String sessionId,
  }) => guardApi(() async {
    final res = await _dio.post(
      ApiEndpoints.executePayment,
      data: {'payment_id': paymentId, 'session_id': sessionId},
    );
    return PaymentExecution.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  });

  /// Cards this customer saved earlier. `session` already returns them, so this
  /// is for the manage-cards surface rather than the payment sheet.
  Future<List<SavedCard>> savedCards() => guardApi(() async {
    final res = await _dio.get(ApiEndpoints.savedCards);
    final data = res.data;
    final rows = data is Map
        ? (data['results'] as List? ?? const [])
        : const [];
    return rows
        .whereType<Map>()
        .map((e) => SavedCard.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  });

  /// Forget a card at the gateway, not merely here — a local-only delete would
  /// leave it chargeable after the customer was told it was gone.
  Future<void> deleteSavedCard(String token) =>
      guardApi(() async => _dio.delete(ApiEndpoints.savedCard(token)));

  /// Which methods the merchant account can take. Falls back rather than
  /// throwing: a sheet with card and KNET beats no sheet at all.
  Future<PaymentMethods> methods() async {
    try {
      final res = await _dio.get(ApiEndpoints.paymentMethods);
      return PaymentMethods.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } catch (_) {
      return PaymentMethods.fallback;
    }
  }
}

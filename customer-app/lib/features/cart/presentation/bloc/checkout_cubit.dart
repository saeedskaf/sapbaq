import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/payments/payment_gateway.dart';
import 'package:sapbaq/core/payments/payment_sheet.dart';
import 'package:sapbaq/features/cart/data/cart_repository.dart';
import 'package:sapbaq/features/orders/data/orders_repository.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';

class CheckoutState extends Equatable {
  final FormStatus status;
  final String? message;
  final int? orderId;

  /// The attempt started but the gateway hasn't settled it. Distinct from a
  /// refusal: the charge may still land, so the wording must not promise
  /// either way (backend answers §3).
  final bool paymentPending;

  /// The gateway refused the card, as opposed to us failing to settle.
  final bool paymentDeclined;

  /// The carts the server refused to combine — two different coupons, or two
  /// gift cards, in one payment (FLUTTER_COMBINED_CHECKOUT §5).
  ///
  /// Empty for every other failure. The server's message already explains the
  /// rule; these ids are what turn it into something the customer can act on
  /// without hunting through their carts for the culprit.
  final List<int> conflictCartIds;

  const CheckoutState({
    this.status = FormStatus.initial,
    this.message,
    this.orderId,
    this.paymentPending = false,
    this.paymentDeclined = false,
    this.conflictCartIds = const [],
  });

  @override
  List<Object?> get props => [
    status,
    message,
    orderId,
    paymentPending,
    paymentDeclined,
    conflictCartIds,
  ];
}

/// Checks carts out into ONE order across every destination, then takes the
/// customer through a single payment for the lot (FLUTTER_COMBINED_CHECKOUT).
///
/// This used to be two methods: one cart at a time, and a loop that checked out
/// and paid each cart in turn — one order, one gateway page and one chance to
/// fail per mosque. The server now combines them, so the loop is gone and with
/// it every state it needed ("payment 2 of 3", "paid 1 of 3"): there is one
/// amount, one attempt, and one outcome.
///
/// Payment needs a [BuildContext] because a live gateway shows a hosted page;
/// the cubit therefore takes one per call rather than holding it.
class CheckoutCubit extends Cubit<CheckoutState> {
  final CartRepository _cart;
  final PaymentGateway _gateway;
  final PaymentRepository _payments;
  final OrdersRepository _orders;

  CheckoutCubit(this._cart, this._payments, this._orders)
    : _gateway = PaymentGateway(_payments),
      super(const CheckoutState());

  /// Refusals that name the carts at fault, rather than just describing a rule.
  static const _conflictCodes = {
    'multiple_coupons_in_checkout',
    'multiple_gifts_in_checkout',
  };

  /// The carts a refusal blames, or none. Deliberately narrow: highlighting a
  /// cart the server didn't name would point the customer at the wrong one.
  static List<int> _conflictCarts(ApiException e) {
    if (!_conflictCodes.contains(e.code)) return const [];
    final ids = e.details['cart_ids'];
    if (ids is! List) return const [];
    return [
      for (final id in ids)
        if (id is int) id,
    ];
  }

  /// Retires a refusal once the carts it named have changed. The customer has
  /// been to fix one of them, and a red border still pointing at a cart whose
  /// coupon has just been removed is worse than no border at all.
  void clearConflicts() {
    if (state.conflictCartIds.isEmpty) return;
    emit(const CheckoutState());
  }

  /// The order is the only honest answer to "did the money land?" — the server
  /// settles payments on its own, so a failed `confirm` proves nothing.
  Future<bool> _isOrderPaid(int orderId) async {
    final order = await _orders.fetchOrder(orderId);
    return !order.isPending;
  }

  /// [cartIds] left null pays **everything** — the server decides what is open
  /// at that moment, which is both simpler and less wrong than sending a list
  /// the screen assembled. Pass a single id to pay one mosque on its own.
  Future<void> confirm(
    BuildContext context, {
    List<int>? cartIds,
    String? notes,
  }) async {
    emit(const CheckoutState(status: FormStatus.submitting));
    final CheckoutResult checkout;
    try {
      checkout = await _cart.checkout(cartIds: cartIds, notes: notes);
    } on ApiException catch (e) {
      emit(
        CheckoutState(
          status: FormStatus.failure,
          message: e.message,
          conflictCartIds: _conflictCarts(e),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final orderId = checkout.orderId;
    final destinations = checkout.destinationCount;
    final result = await _gateway.run(
      context,
      initiate: () => _payments.initiateOrderPayment(orderId),
      verifyPaid: () => _isOrderPaid(orderId),
      target: PaymentTarget.order(orderId, destinations: destinations),
      destinationCount: destinations,
    );
    // Backed out of the sheet: the carts are already an order, so send them to
    // it rather than reporting a failure for something they chose not to do.
    if (result.isDismissed) {
      emit(CheckoutState(status: FormStatus.initial, orderId: orderId));
      return;
    }
    // The order exists either way — an unpaid one stays PENDING and can be paid
    // again from «طلباتي», so the id travels with both outcomes.
    emit(
      CheckoutState(
        status: result.isPaid ? FormStatus.success : FormStatus.failure,
        orderId: orderId,
        message: result.isPaid ? null : result.message,
        paymentPending: result.isPending,
        paymentDeclined: result.isDeclined,
      ),
    );
  }
}

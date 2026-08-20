import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/cart/data/cart_repository.dart';
import 'package:sapbaq/features/cart/data/models/cart.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';

class CartState extends Equatable {
  final LoadStatus status;
  final List<DonationCart> carts;
  final bool mutating;
  final String? message;

  /// The destination the next add-to-cart will use (chosen via the picker on
  /// first add, or a mosque-first entry). Kept sticky for the session.
  final DonationDestination? currentDestination;

  const CartState({
    this.status = LoadStatus.initial,
    this.carts = const [],
    this.mutating = false,
    this.message,
    this.currentDestination,
  });

  bool get isEmpty => carts.isEmpty;

  /// Total items across all carts (drives the floating cart badge).
  int get itemCount => carts.fold(0, (sum, c) => sum + c.itemCount);

  /// Combined total across all carts — now what one payment actually settles,
  /// not just a badge figure, since checkout combines every cart into a single
  /// order. Provisional all the same: one coupon is discounted against the
  /// combined total server-side (§5), so the amount on the payment sheet is the
  /// one that counts. Money is 2-decimal per the backend policy.
  String get totalAmount {
    final sum = carts.fold<double>(
      0,
      (acc, c) => acc + (double.tryParse(c.totalAmount) ?? 0),
    );
    return sum.toStringAsFixed(2);
  }

  CartState copyWith({
    LoadStatus? status,
    List<DonationCart>? carts,
    bool? mutating,
    String? message,
    DonationDestination? currentDestination,
  }) {
    return CartState(
      status: status ?? this.status,
      carts: carts ?? this.carts,
      mutating: mutating ?? this.mutating,
      message: message, // transient — cleared unless explicitly set
      currentDestination: currentDestination ?? this.currentDestination,
    );
  }

  @override
  List<Object?> get props => [
    status,
    carts,
    mutating,
    message,
    currentDestination,
  ];
}

/// App-global donation carts (one per destination). Provided once at the root so
/// the floating badge and the cart screen share one source of truth.
class CartCubit extends Cubit<CartState> {
  final CartRepository _repo;
  CartCubit(this._repo) : super(const CartState());

  /// Clear the in-memory carts locally (guest switch) + the sticky destination.
  void reset() => emit(const CartState());

  /// Set the sticky donation destination for subsequent add-to-cart actions
  /// (driven by the Home destination bar, the picker, or a mosque-first entry).
  void selectDestination(DonationDestination destination) =>
      emit(state.copyWith(currentDestination: destination));

  Future<void> load() async {
    if (state.status == LoadStatus.loading) return;
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final carts = await _repo.getCarts();
      emit(state.copyWith(status: LoadStatus.success, carts: carts));
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  Future<bool> addItem({
    required int productId,
    required int quantity,
    required DonationDestination destination,
    int? variantId,
    String? dedicationName,
    String? dedicationStatus,
  }) {
    return _mutate(
      () => _repo.addItem(
        productId: productId,
        quantity: quantity,
        destination: destination,
        variantId: variantId,
        dedicationName: dedicationName,
        dedicationStatus: dedicationStatus,
      ),
    );
  }

  Future<bool> updateQuantity(int itemId, int quantity) =>
      _mutate(() => _repo.updateQuantity(itemId, quantity));

  Future<bool> removeItem(int itemId) =>
      _mutate(() => _repo.removeItem(itemId));

  Future<bool> deleteCart(int cartId) =>
      _mutate(() => _repo.deleteCart(cartId));

  Future<bool> changeDestination(int cartId, DonationDestination destination) =>
      _mutate(() => _repo.changeDestination(cartId, destination));

  /// Coupon failure nests the useful message under `details.coupon`; surface it.
  Future<bool> applyCoupon(int cartId, String code) async {
    emit(state.copyWith(mutating: true));
    try {
      final carts = await _repo.applyCoupon(cartId, code);
      emit(
        state.copyWith(
          status: LoadStatus.success,
          carts: carts,
          mutating: false,
        ),
      );
      return true;
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          mutating: false,
          message: e.fieldError('coupon') ?? e.message,
        ),
      );
      return false;
    }
  }

  Future<bool> removeCoupon(int cartId) =>
      _mutate(() => _repo.removeCoupon(cartId));

  Future<bool> attachGift(
    int cartId, {
    required String dedicatedToName,
    required String senderName,
    required String notifyPhone,
  }) {
    return _mutate(
      () => _repo.attachGift(
        cartId,
        dedicatedToName: dedicatedToName,
        senderName: senderName,
        notifyPhone: notifyPhone,
      ),
    );
  }

  Future<bool> removeGift(int cartId) =>
      _mutate(() => _repo.removeGift(cartId));

  Future<bool> _mutate(Future<List<DonationCart>> Function() action) async {
    emit(state.copyWith(mutating: true));
    try {
      final carts = await action();
      emit(
        state.copyWith(
          status: LoadStatus.success,
          carts: carts,
          mutating: false,
        ),
      );
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(mutating: false, message: e.message));
      return false;
    }
  }
}

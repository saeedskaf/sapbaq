import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/cart/data/cart_repository.dart';
import 'package:sapbaq/features/cart/data/models/cart.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/gifts/data/gifts_repository.dart';
import 'package:sapbaq/features/gifts/data/models/gift.dart';

class CartState extends Equatable {
  final LoadStatus status;
  final Cart cart;
  final Gift? gift;
  final bool mutating;
  final String? message;

  const CartState({
    this.status = LoadStatus.initial,
    this.cart = Cart.empty,
    this.gift,
    this.mutating = false,
    this.message,
  });

  int get itemCount => cart.itemCount;

  CartState copyWith({
    LoadStatus? status,
    Cart? cart,
    Gift? gift,
    bool clearGift = false,
    bool? mutating,
    String? message,
  }) {
    return CartState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      gift: clearGift ? null : (gift ?? this.gift),
      mutating: mutating ?? this.mutating,
      message: message, // transient — cleared unless explicitly set
    );
  }

  @override
  List<Object?> get props => [status, cart, gift, mutating, message];
}

/// App-global cart (+ its gift). Provided once at the root so the bottom-nav
/// badge and the cart screen share one source of truth.
class CartCubit extends Cubit<CartState> {
  final CartRepository _repo;
  final GiftsRepository _gifts;
  CartCubit(this._repo, this._gifts) : super(const CartState());

  /// Clear the in-memory cart locally (no API call). Used when switching to
  /// guest mode — the cart is account-bound server-side, so a guest has none
  /// and must not see a previous session's items.
  void reset() => emit(const CartState());

  Future<void> load() async {
    if (state.status == LoadStatus.loading) return; // a load is already in flight
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final cart = await _repo.getCart();
      Gift? gift;
      try {
        gift = await _gifts.getGift();
      } catch (_) {
        gift = null; // a gift error shouldn't block the cart
      }
      emit(
        state.copyWith(
          status: LoadStatus.success,
          cart: cart,
          gift: gift,
          clearGift: gift == null,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, message: e.message));
    }
  }

  /// Returns true on success (so the UI can confirm "added").
  Future<bool> addItem({
    required int productId,
    required int quantity,
    required DonationDestination destination,
  }) {
    return _mutate(
      () => _repo.addItem(
        productId: productId,
        quantity: quantity,
        destination: destination,
      ),
    );
  }

  Future<bool> updateQuantity(int itemId, int quantity) =>
      _mutate(() => _repo.updateQuantity(itemId, quantity));

  Future<bool> removeItem(int itemId) =>
      _mutate(() => _repo.removeItem(itemId));

  Future<bool> removeGroup(int groupId) =>
      _mutate(() => _repo.removeGroup(groupId));

  /// Apply a coupon. On failure the backend nests the useful message under
  /// `details.coupon` (e.g. "الكوبون غير موجود…") while the top-level message
  /// is generic — surface the field-specific one.
  Future<bool> applyCoupon(String code) async {
    emit(state.copyWith(mutating: true));
    try {
      final cart = await _repo.applyCoupon(code);
      emit(
        state.copyWith(status: LoadStatus.success, cart: cart, mutating: false),
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

  Future<bool> removeCoupon() => _mutate(_repo.removeCoupon);

  Future<bool> attachGift({
    required String dedicatedToName,
    required String senderName,
    required String notifyPhone,
    required int templateId,
  }) async {
    emit(state.copyWith(mutating: true));
    try {
      final gift = await _gifts.attachGift(
        dedicatedToName: dedicatedToName,
        senderName: senderName,
        notifyPhone: notifyPhone,
        templateId: templateId,
      );
      emit(state.copyWith(status: LoadStatus.success, gift: gift, mutating: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(mutating: false, message: e.message));
      return false;
    }
  }

  Future<bool> removeGift() async {
    emit(state.copyWith(mutating: true));
    try {
      await _gifts.removeGift();
      emit(state.copyWith(status: LoadStatus.success, clearGift: true, mutating: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(mutating: false, message: e.message));
      return false;
    }
  }

  Future<bool> _mutate(Future<Cart> Function() action) async {
    emit(state.copyWith(mutating: true));
    try {
      final cart = await action();
      emit(
        state.copyWith(status: LoadStatus.success, cart: cart, mutating: false),
      );
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(mutating: false, message: e.message));
      return false;
    }
  }
}

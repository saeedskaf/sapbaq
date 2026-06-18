import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/cart/data/cart_repository.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';

class CheckoutState extends Equatable {
  final FormStatus status;
  final String? message;
  final int? orderId;

  const CheckoutState({
    this.status = FormStatus.initial,
    this.message,
    this.orderId,
  });

  @override
  List<Object?> get props => [status, message, orderId];
}

/// Confirms the whole cart in one request, then pays it (dev mock).
class CheckoutCubit extends Cubit<CheckoutState> {
  final CartRepository _cart;
  final PaymentRepository _payment;

  CheckoutCubit(this._cart, this._payment) : super(const CheckoutState());

  Future<void> confirm({String? notes}) async {
    emit(const CheckoutState(status: FormStatus.submitting));
    try {
      final orderId = await _cart.checkout(notes: notes);
      await _payment.payOrder(orderId);
      emit(CheckoutState(status: FormStatus.success, orderId: orderId));
    } on ApiException catch (e) {
      emit(CheckoutState(status: FormStatus.failure, message: e.message));
    }
  }
}

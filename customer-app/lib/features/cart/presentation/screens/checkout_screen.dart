import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/features/cart/data/cart_repository.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/cart/presentation/bloc/checkout_cubit.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => CheckoutCubit(
        context.read<CartRepository>(),
        context.read<PaymentRepository>(),
      ),
      child: BlocConsumer<CheckoutCubit, CheckoutState>(
        listener: (context, state) {
          if (state.status == FormStatus.failure && state.message != null) {
            ShowMessage.error(context, state.message!);
          } else if (state.status == FormStatus.success) {
            context.read<CartCubit>().load(); // cart cleared after checkout
            context.goNamed(AppRoutes.orderSuccessName);
          }
        },
        builder: (context, state) {
          final loading = state.status == FormStatus.submitting;
          return Scaffold(
            appBar: AppBar(title: TextCustom.subheading(text: l10n.checkoutTitle)),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                FormFieldCustom(
                  controller: _notesController,
                  label: l10n.notesHint,
                  isRequired: false,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                BlocBuilder<CartCubit, CartState>(
                  builder: (context, cartState) {
                    final cart = cartState.cart;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.colors.border,
                          width: 0.5,
                        ),
                      ),
                      child: _row(
                        l10n.totalLabel,
                        l10n.priceKwd(cart.totalAmount),
                        bold: true,
                      ),
                    );
                  },
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: ButtonCustom.primary(
                text: l10n.confirmAndPay,
                isLoading: loading,
                onPressed: () => context.read<CheckoutCubit>().confirm(
                  notes: _notesController.text.trim(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextCustom(
          text: label,
          fontSize: bold ? 16 : 14,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: bold ? context.colors.textPrimary : context.colors.textSecondary,
        ),
        TextCustom(
          text: value,
          fontSize: bold ? 18 : 14,
          fontWeight: FontWeight.w700,
          color: color ??
              (bold ? context.colors.primary : context.colors.textPrimary),
        ),
      ],
    );
  }
}

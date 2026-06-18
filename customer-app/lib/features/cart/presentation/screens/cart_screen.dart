import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/media_url.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/data/models/cart.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/gifts/data/gift_relation.dart';
import 'package:sapbaq/features/gifts/data/models/gift.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The app shell already loads the cart on entry (for the nav badge). Only
    // fetch here if that hasn't happened yet, to avoid a duplicate request.
    final cubit = context.read<CartCubit>();
    if (cubit.state.status == LoadStatus.initial) cubit.load();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.navCart)),
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state.message != null) ShowMessage.error(context, state.message!);
        },
        builder: (context, state) {
          final cart = state.cart;
          if (state.status == LoadStatus.loading && cart.isEmpty) {
            return const LoadingView();
          }
          if (state.status == LoadStatus.failure && cart.isEmpty) {
            return ErrorView(
              message: state.message ?? l10n.comingSoon,
              retryLabel: l10n.retry,
              onRetry: () => context.read<CartCubit>().load(),
            );
          }
          if (cart.isEmpty) {
            return EmptyView(
              message: l10n.emptyCart,
              icon: Icons.shopping_cart_outlined,
            );
          }
          return RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: () => context.read<CartCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final group in cart.groups) ...[
                  _GroupCard(group: group),
                  const SizedBox(height: 16),
                ],
                _GiftSection(gift: state.gift),
                const SizedBox(height: 20),
                _CouponSection(controller: _couponController, cart: cart),
                const SizedBox(height: 20),
                _SummarySection(cart: cart),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.cart.isEmpty) return const SizedBox.shrink();
          return _CheckoutBar(total: state.cart.totalAmount);
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final CartGroup group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.colors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    group.isMostNeeded
                        ? Icons.volunteer_activism_rounded
                        : Icons.place_rounded,
                    size: 20,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextCustom(
                    text: group.label,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.deleteGroupButton,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: ColorsCustom.error,
                    size: 22,
                  ),
                  onPressed: () =>
                      context.read<CartCubit>().removeGroup(group.groupId),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final item in group.items) _ItemRow(item: item),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final CartItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = context.read<CartCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: item.productName,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                TextCustom(
                  text: l10n.priceKwd(item.lineTotal),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ItemStepper(
            quantity: item.quantity,
            onDecrement: () => item.quantity > 1
                ? cart.updateQuantity(item.itemId, item.quantity - 1)
                : cart.removeItem(item.itemId),
            onIncrement: item.quantity < 99
                ? () => cart.updateQuantity(item.itemId, item.quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _ItemStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback? onIncrement;

  const _ItemStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          _Btn(
            icon: quantity > 1
                ? Icons.remove_rounded
                : Icons.delete_outline_rounded,
            color: quantity > 1 ? context.colors.primary : ColorsCustom.error,
            onTap: onDecrement,
          ),
          SizedBox(
            width: 28,
            child: TextCustom(
              text: '$quantity',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
          ),
          _Btn(
            icon: Icons.add_rounded,
            color: onIncrement == null
                ? context.colors.textHint
                : context.colors.primary,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _Btn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _GiftSection extends StatelessWidget {
  final Gift? gift;
  const _GiftSection({required this.gift});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final g = gift;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.volunteer_activism_rounded,
              size: 18,
              color: context.colors.primary,
            ),
            const SizedBox(width: 8),
            TextCustom(
              text: l10n.giftSectionTitle,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (g == null) const _AddGiftCard() else _GiftCard(gift: g),
      ],
    );
  }
}

class _AddGiftCard extends StatelessWidget {
  const _AddGiftCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () => context.pushNamed(AppRoutes.giftFormName),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.primaryTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom(
                    text: l10n.addGift,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ColorsCustom.primaryDark,
                  ),
                  const SizedBox(height: 2),
                  TextCustom(
                    text: l10n.addGiftDesc,
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_rounded,
              color: context.colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  final Gift gift;
  const _GiftCard({required this.gift});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final url = resolveMediaUrl(gift.template?.image);
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: url == null
                        ? ColoredBox(
                            color: context.colors.surfaceVariant,
                            child: Icon(
                              Icons.card_giftcard_rounded,
                              color: context.colors.primary,
                            ),
                          )
                        : Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: context.colors.surfaceVariant,
                              child: Icon(
                                Icons.card_giftcard_rounded,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextCustom(
                        text: gift.dedicatedToName,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      TextCustom(
                        text: giftRelationLabel(l10n, gift.relationType),
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => context.pushNamed(
                    AppRoutes.giftFormName,
                    extra: gift,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: TextCustom(
                    text: l10n.editGift,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
              ),
              Container(width: 1, height: 22, color: context.colors.border),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => context.read<CartCubit>().removeGift(),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: ColorsCustom.error,
                  ),
                  label: TextCustom(
                    text: l10n.removeButton,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorsCustom.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CouponSection extends StatefulWidget {
  final TextEditingController controller;
  final Cart cart;
  const _CouponSection({required this.controller, required this.cart});

  @override
  State<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<_CouponSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CartCubit>();
    final cart = widget.cart;

    // Applied → show the code with a remove action.
    if (cart.hasCoupon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.primaryTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_offer_rounded,
              size: 18,
              color: context.colors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextCustom(
                text: cart.couponCode,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ColorsCustom.primaryDark,
              ),
            ),
            TextButton(
              onPressed: () => cubit.removeCoupon(),
              child: TextCustom(
                text: l10n.removeButton,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorsCustom.error,
              ),
            ),
          ],
        ),
      );
    }

    // Collapsed → a tappable "add coupon" row (hides the input until needed).
    if (!_expanded) {
      return Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => setState(() => _expanded = true),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 20,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextCustom(
                    text: l10n.addCoupon,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Expanded → the input + apply button.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FormFieldCustom(
            controller: widget.controller,
            hintText: l10n.couponHint,
            isRequired: false,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 96,
          height: 52,
          child: ButtonCustom.primary(
            text: l10n.applyButton,
            onPressed: () {
              final code = widget.controller.text.trim();
              if (code.isNotEmpty) cubit.applyCoupon(code);
            },
          ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  final Cart cart;
  const _SummarySection({required this.cart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasDiscount = (double.tryParse(cart.discountAmount) ?? 0) > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _row(context, l10n.subtotalLabel, l10n.priceKwd(cart.subtotal)),
          if (hasDiscount) ...[
            const SizedBox(height: 8),
            _row(
              context,
              l10n.discountLabel,
              '- ${l10n.priceKwd(cart.discountAmount)}',
              color: ColorsCustom.success,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _row(context, l10n.totalLabel, l10n.priceKwd(cart.totalAmount), bold: true),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false, Color? color}) {
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
          color: color ?? (bold ? context.colors.primary : context.colors.textPrimary),
        ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final String total;
  const _CheckoutBar({required this.total});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextCustom(
                  text: l10n.totalLabel,
                  fontSize: 12,
                  color: context.colors.textSecondary,
                ),
                TextCustom(
                  text: l10n.priceKwd(total),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 180,
            child: ButtonCustom.primary(
              text: l10n.checkoutButton,
              onPressed: () => context.pushNamed(AppRoutes.checkoutName),
            ),
          ),
        ],
      ),
    );
  }
}

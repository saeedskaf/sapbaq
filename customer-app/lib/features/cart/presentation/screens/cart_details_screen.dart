import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/confirm_sheet.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_form_field.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/most_needed_badge.dart';
import 'package:sapbaq/core/widgets/price_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/product_thumb.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/data/cart_repository.dart';
import 'package:sapbaq/features/cart/data/models/cart.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/cart/presentation/bloc/checkout_cubit.dart';
import 'package:sapbaq/features/cart/presentation/widgets/destination_picker_sheet.dart';
import 'package:sapbaq/features/gifts/data/models/gift.dart';
import 'package:sapbaq/features/gifts/presentation/screens/gift_form_screen.dart';
import 'package:sapbaq/features/orders/data/orders_repository.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Thin route wrapper for `/cart/:id` — the multi-cart list pushes one of
/// these per destination. The content lives in [CartDetailsView] so
/// [CartScreen] can embed the same view directly when there is only one cart.
class CartDetailsScreen extends StatelessWidget {
  final int cartId;

  const CartDetailsScreen({super.key, required this.cartId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: TextCustom.subheading(text: l10n.navCart)),
      body: CartDetailsView(cartId: cartId),
    );
  }
}

/// One cart, start to finish: destination header, items, gift, driver notes,
/// totals (with the one-line coupon row), and the pay footer. Checkout happens
/// right here — the old intermediate checkout screen is gone, so «تأكيد
/// والدفع» goes straight to the hosted payment page.
class CartDetailsView extends StatefulWidget {
  final int cartId;

  const CartDetailsView({super.key, required this.cartId});

  @override
  State<CartDetailsView> createState() => _CartDetailsViewState();
}

class _CartDetailsViewState extends State<CartDetailsView> {
  /// Driver notes — owned here (not by a checkout form) so the pay footer can
  /// read it at confirmation time.
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<CartCubit>();
    if (cubit.state.status == LoadStatus.initial) cubit.load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DonationCart? _findCart(CartState state) {
    for (final cart in state.carts) {
      if (cart.cartId == widget.cartId) return cart;
    }
    return null;
  }

  Future<void> _changeDestination(DonationCart cart) async {
    final destination = await showDestinationPicker(context);
    if (destination == null || !mounted) return;
    await context.read<CartCubit>().changeDestination(cart.cartId, destination);
  }

  Future<void> _confirmDelete(DonationCart cart) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmSheet.ask(
      context,
      title: l10n.deleteCartTitle,
      body: l10n.deleteCartBody(cart.label),
      icon: Icons.delete_outline_rounded,
      confirmLabel: l10n.deleteButton,
      cancelLabel: l10n.cancelButton,
    );
    if (!confirmed || !mounted) return;
    final deleted = await context.read<CartCubit>().deleteCart(cart.cartId);
    // Pushed mode pops back to the list; embedded in [CartScreen] this pops
    // the whole cart flow — deleting your only cart should leave it anyway.
    if (deleted && mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => CheckoutCubit(
        context.read<CartRepository>(),
        context.read<PaymentRepository>(),
        context.read<OrdersRepository>(),
      ),
      child: BlocListener<CheckoutCubit, CheckoutState>(
        listener: (context, state) {
          if (state.status == FormStatus.failure) {
            // A pending attempt may still settle server-side — say so without
            // promising either way. Anything else is an actionable failure.
            if (state.paymentPending) {
              ShowMessage.info(context, l10n.payPendingBody);
            } else {
              ShowMessage.error(
                context,
                state.message ??
                    (state.paymentDeclined
                        ? l10n.payDeclinedBody
                        : l10n.payFailedBody),
              );
            }
            // The cart survives a failed payment — the server only clears it
            // once the money lands. Refresh from the source of truth; the
            // customer is already standing on their intact cart.
            context.read<CartCubit>().load();
          } else if (state.status == FormStatus.success) {
            context.read<CartCubit>().load(); // this cart is consumed
            context.goNamed(AppRoutes.orderSuccessName, extra: state.orderId);
          }
        },
        child: BlocConsumer<CartCubit, CartState>(
          listenWhen: (previous, current) =>
              previous.message != current.message && current.message != null,
          listener: (context, state) =>
              ShowMessage.error(context, state.message!),
          builder: (context, state) {
            final cart = _findCart(state);
            return Column(
              children: [
                Expanded(child: _buildBody(context, state, cart)),
                if (cart != null)
                  _CheckoutFooter(
                    cart: cart,
                    notesController: _notesController,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CartState state, DonationCart? cart) {
    final l10n = AppLocalizations.of(context)!;
    if (state.status == LoadStatus.loading && state.isEmpty) {
      return const LoadingView();
    }
    if (state.status == LoadStatus.failure && state.isEmpty) {
      return ErrorView(
        message: state.message ?? l10n.comingSoon,
        retryLabel: l10n.retry,
        onRetry: () => context.read<CartCubit>().load(),
      );
    }
    if (cart == null) {
      return EmptyView(
        message: l10n.emptyCart,
        icon: Icons.shopping_cart_outlined,
      );
    }
    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: () => context.read<CartCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _DestinationCard(
            cart: cart,
            onChangeDestination: () => _changeDestination(cart),
            onDelete: () => _confirmDelete(cart),
          ),
          const SizedBox(height: 16),
          _ItemsCard(cart: cart, isMutating: state.mutating),
          const SizedBox(height: 16),
          _GiftCard(
            cart: cart,
            isMutating: state.mutating,
            onAdd: () => context.pushNamed(
              AppRoutes.giftFormName,
              extra: GiftFormArgs(cart.cartId),
            ),
            onEdit: (gift) => context.pushNamed(
              AppRoutes.giftFormName,
              extra: GiftFormArgs(cart.cartId, existing: gift),
            ),
          ),
          const SizedBox(height: 16),
          _NotesRow(controller: _notesController),
          const SizedBox(height: 16),
          _CouponTicket(cart: cart, isMutating: state.mutating),
          const SizedBox(height: 16),
          _TotalsCard(cart: cart),
        ],
      ),
    );
  }
}

/// Collapsed one-line «ملاحظات للسائق» row that expands in place to a compact
/// field — the whole reason the old checkout screen existed, folded into the
/// cart itself.
class _NotesRow extends StatefulWidget {
  final TextEditingController controller;

  const _NotesRow({required this.controller});

  @override
  State<_NotesRow> createState() => _NotesRowState();
}

class _NotesRowState extends State<_NotesRow> {
  late bool _expanded = widget.controller.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SurfaceCard(
      child: !_expanded
          ? InkWell(
              onTap: () => setState(() => _expanded = true),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 20,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextCustom(
                        text: l10n.notesHint,
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: context.colors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  icon: Icons.edit_note_rounded,
                  text: l10n.notesHint,
                ),
                const SizedBox(height: 10),
                FormFieldCustom(
                  controller: widget.controller,
                  hintText: l10n.notesHint,
                  isRequired: false,
                  maxLines: 3,
                ),
              ],
            ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final DonationCart cart;
  final VoidCallback onChangeDestination;
  final VoidCallback onDelete;

  const _DestinationCard({
    required this.cart,
    required this.onChangeDestination,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          _DestinationIcon(cart: cart),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: TextCustom(
                        // The mosque's full name, however long — the donor is
                        // paying for THIS mosque, so it never truncates.
                        text: cart.label,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (cart.isMostNeeded) ...[
                      const SizedBox(width: 6),
                      const MostNeededBadge(),
                    ],
                  ],
                ),
                if (cart.area?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 3),
                  TextCustom(
                    text: cart.area!,
                    fontSize: 12.5,
                    color: context.colors.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Two quiet 36px actions instead of the old full-width button: the
          // destination is a fact to glance at, not the page's main act.
          _HeaderAction(
            icon: Icons.edit_location_alt_outlined,
            tooltip: l10n.changeDestination,
            background: context.colors.surfaceVariant,
            foreground: context.colors.primary,
            onTap: onChangeDestination,
          ),
          const SizedBox(width: 8),
          _HeaderAction(
            icon: Icons.delete_outline_rounded,
            tooltip: l10n.deleteButton,
            background: context.colors.danger.withValues(alpha: 0.10),
            foreground: context.colors.danger,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Small circular header action (change destination / delete cart).
class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: foreground),
          ),
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final DonationCart cart;
  final bool isMutating;

  const _ItemsCard({required this.cart, required this.isMutating});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: context.colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextCustom(
                    text: l10n.productsTitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextCustom(
                    text: l10n.itemsCount(cart.itemCount),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.colors.border),
          for (var index = 0; index < cart.items.length; index++) ...[
            _CartItemRow(item: cart.items[index], isMutating: isMutating),
            if (index < cart.items.length - 1)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 16),
                child: Divider(height: 1, color: context.colors.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final bool isMutating;

  const _CartItemRow({required this.item, required this.isMutating});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = context.read<CartCubit>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // No thumb for a product without a photo — the row must not reserve
          // an empty well.
          if (item.image != null) ...[
            ProductThumb(url: item.image),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  // Product + picked variant, e.g. «براد سبيل — بحنفيتين».
                  text: item.displayName,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.dedicationName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _DedicationBadge(
                    name: item.dedicationName,
                    status: item.dedicationStatus,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextCustom(
                      text: l10n.priceKwd(item.lineTotal),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: context.colors.primary,
                    ),
                    if (item.hasDiscount) ...[
                      const SizedBox(width: 8),
                      // A step below the 13pt line total beside it — the cart
                      // row is the one surface where the live price is itself
                      // small, so the struck one has to stay subordinate.
                      StruckPrice(amount: item.listPrice, fontSize: 12),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _QuantityControl(
            quantity: item.quantity,
            onDecrement: isMutating
                ? null
                : () {
                    if (item.quantity > 1) {
                      cart.updateQuantity(item.itemId, item.quantity - 1);
                    } else {
                      cart.removeItem(item.itemId);
                    }
                  },
            onIncrement: isMutating || item.quantity >= 99
                ? null
                : () => cart.updateQuantity(item.itemId, item.quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final decrementColor = onDecrement == null
        ? context.colors.textHint
        : quantity == 1
        ? context.colors.danger
        : context.colors.primary;
    final incrementColor = onIncrement == null
        ? context.colors.textHint
        : context.colors.primary;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityAction(
            icon: quantity == 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            color: decrementColor,
            onTap: onDecrement,
          ),
          SizedBox(
            width: 30,
            child: TextCustom(
              text: '$quantity',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              textAlign: TextAlign.center,
            ),
          ),
          _QuantityAction(
            icon: Icons.add_rounded,
            color: incrementColor,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _QuantityAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuantityAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 34,
        height: 40,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  final DonationCart cart;
  final bool isMutating;
  final VoidCallback onAdd;
  final ValueChanged<Gift> onEdit;

  const _GiftCard({
    required this.cart,
    required this.isMutating,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gift = cart.gift;
    if (gift == null) {
      return _SurfaceCard(
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: context.colors.textSecondary,
                  size: 22,
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
                      fontWeight: FontWeight.w800,
                    ),
                    const SizedBox(height: 3),
                    TextCustom(
                      text: l10n.addGiftDesc,
                      fontSize: 12,
                      color: context.colors.textSecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.colors.textHint),
            ],
          ),
        ),
      );
    }
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.card_giftcard_outlined,
            text: l10n.giftSectionTitle,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // The card artwork is composed server-side and never shown to
                // the donor, so this stays a plain mark.
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: context.colors.primary,
                    size: 28,
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
                        fontWeight: FontWeight.w800,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      TextCustom(
                        text: l10n.giftFromName(gift.senderName),
                        fontSize: 12,
                        color: context.colors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.editGift,
                  onPressed: isMutating ? null : () => onEdit(gift),
                  icon: Icon(
                    Icons.edit_outlined,
                    color: context.colors.primary,
                  ),
                ),
                IconButton(
                  tooltip: l10n.removeButton,
                  onPressed: isMutating
                      ? null
                      : () => context.read<CartCubit>().removeGift(cart.cartId),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: context.colors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final DonationCart cart;

  const _TotalsCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasDiscount = (double.tryParse(cart.discountAmount) ?? 0) > 0;
    return _SurfaceCard(
      child: Column(
        children: [
          _SectionTitle(
            icon: Icons.receipt_long_outlined,
            text: l10n.totalLabel,
          ),
          const SizedBox(height: 16),
          _AmountRow(
            label: l10n.subtotalLabel,
            value: l10n.priceKwd(cart.subtotal),
          ),
          if (hasDiscount) ...[
            const SizedBox(height: 10),
            _AmountRow(
              // Name the code when the discount comes from one — the amount
              // itself lives only here, never on the coupon ticket.
              label: cart.hasCoupon
                  ? '${l10n.discountLabel} (${cart.couponCode})'
                  : l10n.discountLabel,
              value: '- ${l10n.priceKwd(cart.discountAmount)}',
              valueColor: ColorsCustom.success,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: context.colors.border),
          ),
          _AmountRow(
            label: l10n.totalLabel,
            value: l10n.priceKwd(cart.totalAmount),
            isEmphasized: true,
          ),
        ],
      ),
    );
  }
}

/// The coupon entry, styled as the classic dashed «ticket» just above the
/// totals. Three states in one frame: a quiet prompt, an inline field once
/// opened, and a settled (solid-border) confirmation with the code and its
/// remove ×. The discount *amount* lives only in the totals card.
class _CouponTicket extends StatefulWidget {
  final DonationCart cart;
  final bool isMutating;

  const _CouponTicket({required this.cart, required this.isMutating});

  @override
  State<_CouponTicket> createState() => _CouponTicketState();
}

class _CouponTicketState extends State<_CouponTicket> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _expanded = true);
    _focusNode.requestFocus();
  }

  Future<void> _apply() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    final applied = await context.read<CartCubit>().applyCoupon(
      widget.cart.cartId,
      code,
    );
    if (!mounted || !applied) return;
    setState(() {
      _expanded = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final applied = widget.cart.hasCoupon;
    return CustomPaint(
      // The dashes go in front so the fill can't cover them; an applied
      // ticket settles from dashed to a solid frame.
      foregroundPainter: _TicketBorderPainter(
        color: context.colors.primary.withValues(alpha: applied ? 0.55 : 0.45),
        radius: 14,
        dashed: !applied,
      ),
      child: Material(
        color: applied
            ? context.colors.surfaceVariant.withValues(alpha: 0.45)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: applied || _expanded ? null : _open,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: applied
                ? _appliedRow(context, l10n)
                : _expanded
                ? _fieldRow(context, l10n)
                : _promptRow(context, l10n),
          ),
        ),
      ),
    );
  }

  Widget _ticketIcon(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.local_offer_rounded,
        size: 15,
        color: context.colors.textSecondary,
      ),
    );
  }

  Widget _promptRow(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        _ticketIcon(context),
        const SizedBox(width: 10),
        Expanded(
          child: TextCustom(
            text: l10n.haveCoupon,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        Icon(
          Icons.add_circle_outline_rounded,
          size: 20,
          color: context.colors.primary,
        ),
      ],
    );
  }

  Widget _fieldRow(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: FormFieldCustom(
            controller: _controller,
            focusNode: _focusNode,
            hintText: l10n.couponHint,
            isRequired: false,
            enabled: !widget.isMutating,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _apply(),
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(width: 8),
        if (widget.isMutating)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.primary,
              ),
            ),
          )
        else
          TextButton(
            onPressed: _controller.text.trim().isEmpty ? null : _apply,
            child: TextCustom(
              text: l10n.applyButton,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _controller.text.trim().isEmpty
                  ? context.colors.textHint
                  : context.colors.primary,
            ),
          ),
      ],
    );
  }

  Widget _appliedRow(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        _ticketIcon(context),
        const SizedBox(width: 10),
        // One line only — the solid frame and tint already say "applied", and
        // the amount lives in the totals card.
        Expanded(
          child: TextCustom(
            text: widget.cart.couponCode,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Tooltip(
          message: l10n.removeButton,
          child: InkWell(
            onTap: widget.isMutating
                ? null
                : () => context.read<CartCubit>().removeCoupon(
                    widget.cart.cartId,
                  ),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 30,
              height: 30,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: widget.isMutating
                    ? context.colors.textHint
                    : context.colors.danger,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rounded ticket frame — dashed while the coupon is an invitation, solid once
/// one is applied.
class _TicketBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final bool dashed;

  const _TicketBorderPainter({
    required this.color,
    required this.radius,
    required this.dashed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.65),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_TicketBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dashed != dashed;
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isEmphasized;

  const _AmountRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isEmphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextCustom(
          text: label,
          fontSize: isEmphasized ? 15 : 13,
          fontWeight: isEmphasized ? FontWeight.w800 : FontWeight.w500,
          color: isEmphasized
              ? context.colors.textPrimary
              : context.colors.textSecondary,
        ),
        TextCustom(
          text: value,
          fontSize: isEmphasized ? 17 : 14,
          fontWeight: FontWeight.w800,
          color:
              valueColor ??
              (isEmphasized
                  ? context.colors.primary
                  : context.colors.textPrimary),
        ),
      ],
    );
  }
}

/// The pay bar: running total (struck subtotal when a discount applies) and
/// «تأكيد والدفع» — checkout and payment start right here, no extra screen.
class _CheckoutFooter extends StatelessWidget {
  final DonationCart cart;
  final TextEditingController notesController;

  const _CheckoutFooter({required this.cart, required this.notesController});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasDiscount = (double.tryParse(cart.discountAmount) ?? 0) > 0;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
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
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: TextCustom(
                          text: l10n.priceKwd(cart.totalAmount),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.colors.primary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        StruckPrice(amount: cart.subtotal),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 164,
              child: BlocBuilder<CheckoutCubit, CheckoutState>(
                builder: (context, state) {
                  final submitting = state.status == FormStatus.submitting;
                  return ButtonCustom.primary(
                    text: l10n.confirmAndPay,
                    height: 52,
                    isLoading: submitting,
                    onPressed: submitting
                        ? null
                        : () {
                            final notes = notesController.text.trim();
                            // This cart only — the customer opened one
                            // destination and asked to settle it. Paying every
                            // cart is the list screen's button, not this one.
                            context.read<CheckoutCubit>().confirm(
                              context,
                              cartIds: [cart.cartId],
                              notes: notes.isEmpty ? null : notes,
                            );
                          },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.colors.primary),
        const SizedBox(width: 8),
        TextCustom(text: text, fontSize: 15, fontWeight: FontWeight.w800),
      ],
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  final DonationCart cart;

  const _DestinationIcon({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        cart.isMostNeeded
            ? Icons.volunteer_activism_rounded
            : Icons.mosque_outlined,
        color: context.colors.textSecondary,
        size: 25,
      ),
    );
  }
}

/// The engraved name + alive/deceased status shown under a dedication item.
class _DedicationBadge extends StatelessWidget {
  final String name;
  final String status; // ALIVE | DECEASED | ''
  const _DedicationBadge({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = switch (status) {
      'ALIVE' => l10n.dedicationAlive,
      'DECEASED' => l10n.dedicationDeceased,
      _ => '',
    };
    final text = statusLabel.isEmpty ? name : '$name · $statusLabel';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 15,
            color: context.colors.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: TextCustom(
              text: text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

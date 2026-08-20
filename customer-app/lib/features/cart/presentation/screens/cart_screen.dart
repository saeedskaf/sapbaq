import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/form_status.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/most_needed_badge.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/product_thumb.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/data/cart_repository.dart';
import 'package:sapbaq/features/cart/data/models/cart.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/cart/presentation/bloc/checkout_cubit.dart';
import 'package:sapbaq/features/cart/presentation/screens/cart_details_screen.dart';
import 'package:sapbaq/features/orders/data/orders_repository.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<CartCubit>();
    if (cubit.state.status == LoadStatus.initial) cubit.load();
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
      child: MultiBlocListener(
        listeners: [
          BlocListener<CartCubit, CartState>(
            // Any real change to the carts retires the server's last verdict
            // about them — it was passed on a combination that no longer
            // exists, and the highlight it left behind now points at nothing.
            // Element-wise: a reload hands back a fresh list every time, and
            // identity would call an unchanged cart a change.
            listenWhen: (a, b) => !listEquals(a.carts, b.carts),
            listener: (context, _) =>
                context.read<CheckoutCubit>().clearConflicts(),
          ),
          BlocListener<CheckoutCubit, CheckoutState>(
            listener: (context, state) {
              if (state.status == FormStatus.failure) {
                // One payment covers every cart now, so there is no "it got this
                // far" left to report: the whole amount landed or none of it did.
                ShowMessage.error(
                  context,
                  state.paymentPending
                      ? l10n.payPendingBody
                      : state.message ??
                            (state.paymentDeclined
                                ? l10n.payDeclinedBody
                                : l10n.payFailedBody),
                );
                // A refused combination — two coupons, two gift cards — never
                // reached the gateway and changed nothing server-side. Re-reading
                // the carts would cost a round trip to redraw exactly what is
                // already on screen, now marked with which one to fix.
                if (state.conflictCartIds.isEmpty) {
                  context.read<CartCubit>().load();
                }
              } else if (state.status == FormStatus.success) {
                context.read<CartCubit>().load();
                // Every cart became ONE order, so there is finally a single order
                // for the success screen to open — «ادفع الكل» never had one.
                context.goNamed(
                  AppRoutes.orderSuccessName,
                  extra: state.orderId,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: context.colors.background,
              appBar: AppBar(title: TextCustom.subheading(text: l10n.navCart)),
              body: _buildBody(context, state, l10n),
              bottomNavigationBar: state.carts.length < 2
                  ? null
                  : _PayAllFooter(
                      total: state.totalAmount,
                      mosqueCount: state.carts.length,
                      hasCoupon: state.carts.any((cart) => cart.hasCoupon),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CartState state,
    AppLocalizations l10n,
  ) {
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
    if (state.isEmpty) {
      return EmptyView(
        message: l10n.emptyCart,
        icon: Icons.shopping_cart_outlined,
      );
    }
    // One cart — the common case — goes straight to the full details, footer
    // and all: one screen from «عرض السلة» to the payment page. The list view
    // below exists only to arbitrate between destinations.
    if (state.carts.length == 1) {
      return CartDetailsView(cartId: state.carts.first.cartId);
    }
    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: () => context.read<CartCubit>().load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.carts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _CartPreviewCard(cart: state.carts[index]),
      ),
    );
  }
}

/// The pay bar over several destinations: one amount, one payment, every
/// mosque. It used to start a run of payments — one gateway page per cart —
/// which is why it carried a progress line; the server now combines them, so
/// what the bar has to say is no longer "which one of these" but "all of them".
class _PayAllFooter extends StatelessWidget {
  final String total;
  final int mosqueCount;

  /// Some cart carries a coupon. A single coupon is discounted against the
  /// COMBINED total (§5), which is not what the per-cart totals above add up
  /// to — so the bar admits the sum is provisional rather than quietly
  /// disagreeing with the amount on the payment sheet a moment later.
  final bool hasCoupon;

  const _PayAllFooter({
    required this.total,
    required this.mosqueCount,
    required this.hasCoupon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  // The one thing a customer with three carts wants confirmed
                  // before touching a pay button: this is once, not three
                  // times. It stands where the «الدفعة ١ من ٣» counter used to.
                  TextCustom(
                    text: l10n.payOneForMosques(mosqueCount),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                  ),
                  const SizedBox(height: 4),
                  TextCustom(
                    text: l10n.totalLabel,
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(height: 2),
                  TextCustom(
                    text: l10n.priceKwd(total),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.colors.primary,
                  ),
                  if (hasCoupon) ...[
                    const SizedBox(height: 4),
                    TextCustom(
                      text: l10n.couponAppliedToTotal,
                      fontSize: 11,
                      color: context.colors.textSecondary,
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 172,
              child: BlocBuilder<CheckoutCubit, CheckoutState>(
                builder: (context, state) => ButtonCustom.primary(
                  text: l10n.payTotalButton,
                  height: 52,
                  isLoading: state.status == FormStatus.submitting,
                  onPressed: state.status == FormStatus.submitting
                      ? null
                      // No cart ids: the server decides what "all my carts"
                      // means at the instant of checkout, which is the
                      // contract's own advice and one less list to get wrong.
                      : () => context.read<CheckoutCubit>().confirm(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPreviewCard extends StatelessWidget {
  final DonationCart cart;

  const _CartPreviewCard({required this.cart});

  /// First two line names (with ×qty when above one), then «+N» for the rest.
  String _itemsPreview(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final separator = isArabic ? '، ' : ', ';
    final names = [
      for (final item in cart.items.take(2))
        item.quantity > 1
            ? '${item.displayName} ×${item.quantity}'
            : item.displayName,
    ];
    final rest = cart.items.length - names.length;
    final joined = names.join(separator);
    return rest > 0 ? '$joined +$rest' : joined;
  }

  /// Line thumbnails — a line without a photo simply contributes none.
  List<String> get _thumbs => [
    for (final item in cart.items)
      if (item.image != null) item.image!,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // One order carries one coupon and one gift card, so two carts that
    // disagree are refused before anything is created (§5). The server names
    // the carts it means; marking them here is the difference between "you
    // can't do that" and "remove the coupon from this one".
    final blocking = context
        .watch<CheckoutCubit>()
        .state
        .conflictCartIds
        .contains(cart.cartId);
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoutes.cartDetailsName,
          pathParameters: {'id': '${cart.cartId}'},
        ),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: blocking ? context.colors.danger : context.colors.border,
              width: blocking ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                                // Full mosque name — never truncated; it's the
                                // card's whole identity.
                                text: cart.label,
                                fontSize: 15,
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
                          const SizedBox(height: 4),
                          TextCustom(
                            text: cart.area!,
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // What's actually inside — names first, then thumbnails once
              // the backend ships line images. The card must answer "which
              // cart is this?" without opening it.
              TextCustom(
                text: _itemsPreview(context),
                fontSize: 12.5,
                color: context.colors.textSecondary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_thumbs.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final url in _thumbs.take(5)) ...[
                      ProductThumb(url: url, size: 32, radius: 8, padding: 2),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaItem(
                    icon: Icons.inventory_2_outlined,
                    value: l10n.itemsCount(cart.itemCount),
                  ),
                  if (cart.hasCoupon) ...[
                    const SizedBox(width: 12),
                    _MetaItem(
                      icon: Icons.local_offer_outlined,
                      value: cart.couponCode,
                    ),
                  ],
                  if (cart.gift != null) ...[
                    const SizedBox(width: 12),
                    _MetaItem(
                      icon: Icons.card_giftcard_outlined,
                      value: l10n.giftSectionTitle,
                    ),
                  ],
                ],
              ),
              if (blocking) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: context.colors.danger,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextCustom(
                        text: l10n.cartConflictHint,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.colors.danger,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    TextCustom(
                      text: l10n.totalLabel,
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                    const Spacer(),
                    TextCustom(
                      text: l10n.priceKwd(cart.totalAmount),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.colors.textHint,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  final DonationCart cart;

  const _DestinationIcon({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        cart.isMostNeeded
            ? Icons.volunteer_activism_rounded
            : Icons.mosque_outlined,
        color: context.colors.textSecondary,
        size: 23,
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _MetaItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: context.colors.textSecondary),
          const SizedBox(width: 5),
          TextCustom(
            text: value,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

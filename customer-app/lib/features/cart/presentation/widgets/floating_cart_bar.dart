import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// CartCubit-connected "view cart" bar. Renders the bar only when the cart has
/// items and opens the cart on tap. Set [safeAreaBottom] when the bar is the
/// bottom-most element of a screen (no nav/action bar beneath it).
class CartBar extends StatelessWidget {
  final bool safeAreaBottom;
  const CartBar({super.key, this.safeAreaBottom = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (a, b) =>
          a.itemCount != b.itemCount ||
          a.cart.totalAmount != b.cart.totalAmount,
      builder: (context, state) => FloatingCartBar(
        itemCount: state.itemCount,
        total: state.cart.totalAmount,
        onTap: () => context.pushNamed(AppRoutes.cartName),
        safeAreaBottom: safeAreaBottom,
      ),
    );
  }
}

/// A "view cart" bar that slides + fades in when the cart has items, showing the
/// item count and running total, and opening the cart when tapped.
class FloatingCartBar extends StatelessWidget {
  /// Vertical space the bar occupies when visible (content + top gap). The shell
  /// reserves this much extra clearance for page content while it's showing.
  static const double height = 72;

  final int itemCount;
  final String total;
  final VoidCallback onTap;
  final bool safeAreaBottom;

  const FloatingCartBar({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onTap,
    this.safeAreaBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: 1, // grow upward
          child: child,
        ),
      ),
      child: itemCount > 0
          ? _bar(context)
          : const SizedBox(
              width: double.infinity,
              key: ValueKey('cart-bar-hidden'),
            ),
    );
  }

  Widget _bar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const onBrand = ColorsCustom.textOnPrimary; // white content on the brand-green bar
    final bar = Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorsCustom.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: ColorsCustom.surface,
                      shape: BoxShape.circle,
                    ),
                    child: TextCustom(
                      text: itemCount > 99 ? '99+' : '$itemCount',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ColorsCustom.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextCustom(
                    text: l10n.viewCart,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: onBrand,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextCustom(
                        text: l10n.totalLabel,
                        fontSize: 10,
                        color: onBrand.withValues(alpha: 0.7),
                      ),
                      TextCustom(
                        text: l10n.priceKwd(total),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: onBrand,
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: onBrand.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: onBrand,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return KeyedSubtree(
      key: const ValueKey('cart-bar-visible'),
      child: safeAreaBottom ? SafeArea(top: false, child: bar) : bar,
    );
  }
}

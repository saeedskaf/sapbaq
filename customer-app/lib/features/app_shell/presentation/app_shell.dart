import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/cart/presentation/widgets/floating_cart_bar.dart';
import 'package:sapbaq/features/mosques/presentation/bloc/favorites_cubit.dart';
import 'package:sapbaq/features/support/presentation/bloc/support_unread_cubit.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Authenticated app shell: hosts the five bottom-nav tabs with preserved
/// per-tab navigation state (via [StatefulNavigationShell]) and a floating
/// frosted-glass nav bar.
class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    // The cart is account-bound (server-side). Load it for signed-in users;
    // for guests, clear any in-memory cart left over from a previous session
    // so no stale cart bar shows (e.g. on the products page).
    if (context.read<AuthBloc>().state.status == AuthStatus.authenticated) {
      context.read<CartCubit>().load();
      context.read<FavoritesCubit>().load();
      context.read<SupportUnreadCubit>().load();
    } else {
      context.read<CartCubit>().reset();
      context.read<FavoritesCubit>().reset();
      context.read<SupportUnreadCubit>().reset();
    }
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthBloc, AuthState>(
      // When a guest signs in while the shell stays mounted, load their cart.
      listenWhen: (a, b) =>
          a.status != AuthStatus.authenticated &&
          b.status == AuthStatus.authenticated,
      listener: (context, _) {
        context.read<CartCubit>().load();
        context.read<FavoritesCubit>().load();
        context.read<SupportUnreadCubit>().load();
      },
      child: BlocBuilder<CartCubit, CartState>(
        buildWhen: (a, b) =>
            a.itemCount != b.itemCount ||
            a.cart.totalAmount != b.cart.totalAmount,
        builder: (context, state) {
        final isGuest =
            context.watch<AuthBloc>().state.status == AuthStatus.guest;
        final cartCount = isGuest ? 0 : state.itemCount;
        final hasItems = cartCount > 0;
        return Scaffold(
          // Let tab content extend behind the floating bars so the blur picks
          // it up; reserve extra clearance while the cart bar is showing.
          extendBody: true,
          body: FloatingBottomInset(
            extraInset: hasItems ? FloatingCartBar.height : 0,
            child: widget.navigationShell,
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingCartBar(
                itemCount: cartCount,
                total: state.cart.totalAmount,
                onTap: () => context.pushNamed(AppRoutes.cartName),
              ),
              FloatingNavBar(
                currentIndex: widget.navigationShell.currentIndex,
                onTap: _onTap,
                items: _navItems(l10n),
              ),
            ],
          ),
        );
      },
      ),
    );
  }

  List<FloatingNavItem> _navItems(AppLocalizations l10n) {
    return [
      FloatingNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n.navHome,
      ),
      FloatingNavItem(
        icon: Icons.mosque_outlined,
        activeIcon: Icons.mosque,
        label: l10n.navMosques,
      ),
      FloatingNavItem(
        icon: Icons.collections_outlined,
        activeIcon: Icons.collections,
        label: l10n.navMedia,
      ),
      FloatingNavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: l10n.navOrders,
      ),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/auth/auth_guard.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/date_format.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/orders/data/models/order.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/orders/data/orders_repository.dart';
import 'package:sapbaq/features/orders/presentation/bloc/orders_cubit.dart';
import 'package:sapbaq/features/orders/presentation/widgets/status_badge.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Guests have no orders and the endpoint is auth-only — don't even create
    // the cubit (its load would 401). Show a sign-in prompt instead.
    final isGuest =
        context.watch<AuthBloc>().state.status == AuthStatus.guest;
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(title: TextCustom.subheading(text: l10n.ordersTitle)),
        body: GuestGateView(
          title: l10n.loginRequiredTitle,
          message: l10n.guestOrdersMessage,
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          OrdersCubit(context.read<OrdersRepository>())..load(),
      child: Scaffold(
        appBar: AppBar(title: TextCustom.subheading(text: l10n.ordersTitle)),
        body: BlocBuilder<OrdersCubit, OrdersState>(
          builder: (context, state) {
            switch (state.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const LoadingView();
              case LoadStatus.failure:
                return ErrorView(
                  message: state.message ?? l10n.comingSoon,
                  retryLabel: l10n.retry,
                  onRetry: () => context.read<OrdersCubit>().load(),
                );
              case LoadStatus.success:
                if (state.orders.isEmpty) {
                  return EmptyView(
                    message: l10n.emptyOrders,
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: () => context.read<OrdersCubit>().load(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 400) {
                        context.read<OrdersCubit>().loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        floatingNavBarClearance(context),
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount:
                          state.orders.length + (state.loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.orders.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: context.colors.primary,
                              ),
                            ),
                          );
                        }
                        final order = state.orders[index];
                        return _OrderCard(
                          order: order,
                          onTap: () => context.pushNamed(
                            AppRoutes.orderDetailName,
                            pathParameters: {'id': '${order.id}'},
                          ),
                        );
                      },
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = formatShortDate(order.createdAt);
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.colors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: context.colors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextCustom(
                            text: l10n.orderRef(order.shortReference),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (date.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            TextCustom(
                              text: date,
                              fontSize: 12,
                              color: context.colors.textHint,
                            ),
                          ],
                        ],
                      ),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: context.colors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextCustom(
                        text: l10n.destinationsCount(order.destinationCount),
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    TextCustom(
                      text: l10n.priceKwd(order.totalAmount),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.colors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

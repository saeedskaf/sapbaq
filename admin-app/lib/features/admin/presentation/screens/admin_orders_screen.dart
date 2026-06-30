import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/admin_orders_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/admin_order_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/filter_tabs.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AdminOrdersCubit(context.read<AdminRepository>())..load(),
      child: const _AdminOrdersView(),
    );
  }
}

class _AdminOrdersView extends StatefulWidget {
  const _AdminOrdersView();

  @override
  State<_AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<_AdminOrdersView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      context.read<AdminOrdersCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.adminOrdersTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _SearchField(
              controller: _searchController,
              hint: l10n.searchOrdersHint,
              onSubmitted: (q) => context.read<AdminOrdersCubit>().search(q),
            ),
          ),
          BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
            buildWhen: (a, b) => a.tab != b.tab || a.counts != b.counts,
            builder: (context, state) {
              final counts = state.counts;
              String withCount(String label, int? n) =>
                  n == null ? label : '$label ($n)';
              final labels = [
                withCount(l10n.tabAwaiting, counts?.awaitingAssignment),
                withCount(l10n.tabAll, counts?.all),
                withCount(l10n.tabDelivered, counts?.delivered),
                withCount(l10n.tabCancelled, counts?.cancelled),
              ];
              return FilterTabs(
                labels: labels,
                selectedIndex: AdminOrdersTab.values.indexOf(state.tab),
                onChanged: (i) => context
                    .read<AdminOrdersCubit>()
                    .setTab(AdminOrdersTab.values[i]),
              );
            },
          ),
          const SizedBox(height: 10),
          BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
            buildWhen: (a, b) => a.status != b.status || a.total != b.total,
            builder: (context, state) {
              if (state.status != LoadStatus.success || state.total == 0) {
                return const SizedBox(height: 8);
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextCustom(
                    text: l10n.ordersCount(state.total),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: ColorsCustom.textHint,
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
              builder: (context, state) {
                if (state.status == LoadStatus.loading) {
                  return const LoadingView();
                }
                if (state.status == LoadStatus.failure) {
                  return ErrorView(
                    message: state.message ?? l10n.genericError,
                    retryLabel: l10n.retry,
                    onRetry: () => context.read<AdminOrdersCubit>().load(),
                  );
                }
                if (state.orders.isEmpty) {
                  return EmptyView(
                    message: l10n.emptyOrders,
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return RefreshIndicator(
                  color: ColorsCustom.primary,
                  onRefresh: () => context.read<AdminOrdersCubit>().load(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      floatingNavBarClearance(context),
                    ),
                    itemCount: state.orders.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= state.orders.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: ColorsCustom.primary,
                            ),
                          ),
                        );
                      }
                      final order = state.orders[i];
                      return AdminOrderCard(
                        order: order,
                        onTap: () => context.pushNamed(
                          AppRoutes.adminOrderDetailName,
                          pathParameters: {'id': '${order.id}'},
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: ColorsCustom.textHint),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, color: ColorsCustom.textHint),
                onPressed: () {
                  controller.clear();
                  onSubmitted('');
                },
              ),
      ),
    );
  }
}

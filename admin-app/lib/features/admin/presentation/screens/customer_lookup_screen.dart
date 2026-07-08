import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/customer_lookup.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/customer_lookup_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/admin_order_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Customer lookup + history (§7). Search by phone or name; each match shows the
/// customer and their full order history. RETAIL_OPERATOR's primary screen.
class CustomerLookupScreen extends StatelessWidget {
  const CustomerLookupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CustomerLookupCubit(context.read<AdminRepository>()),
      child: const _LookupView(),
    );
  }
}

class _LookupView extends StatefulWidget {
  const _LookupView();

  @override
  State<_LookupView> createState() => _LookupViewState();
}

class _LookupViewState extends State<_LookupView> {
  final _controller = TextEditingController();
  final _idController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: TextCustom.subheading(text: l10n.customerLookupTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (q) {
                      _idController.clear();
                      context.read<CustomerLookupCubit>().search(q);
                    },
                    decoration: InputDecoration(
                      hintText: l10n.lookupHint,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: ColorsCustom.textHint,
                      ),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: ColorsCustom.textHint,
                              ),
                              onPressed: () {
                                _controller.clear();
                                context.read<CustomerLookupCubit>().search('');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Dedicated customer-ID lookup (`?id=`, FLUTTER_TASKS item 3).
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (q) {
                      _controller.clear();
                      context.read<CustomerLookupCubit>().searchById(q);
                    },
                    decoration: InputDecoration(
                      hintText: l10n.lookupIdHint,
                      prefixIcon: const Icon(
                        Icons.tag_rounded,
                        color: ColorsCustom.textHint,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<CustomerLookupCubit, CustomerLookupState>(
              builder: (context, state) => _results(context, state, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _results(
    BuildContext context,
    CustomerLookupState state,
    AppLocalizations l10n,
  ) {
    switch (state.status) {
      case LoadStatus.initial:
        return EmptyView(
          message: l10n.lookupPrompt,
          icon: Icons.person_search_outlined,
        );
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.failure:
        return ErrorView(
          message: state.message ?? l10n.genericError,
          retryLabel: l10n.retry,
          onRetry: () => context.read<CustomerLookupCubit>().retry(),
        );
      case LoadStatus.success:
        if (state.results.isEmpty) {
          return EmptyView(
            message: l10n.lookupNoResults,
            icon: Icons.person_off_outlined,
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            for (final result in state.results)
              _CustomerSection(result: result, l10n: l10n),
          ],
        );
    }
  }
}

class _CustomerSection extends StatelessWidget {
  final CustomerLookupResult result;
  final AppLocalizations l10n;
  const _CustomerSection({required this.result, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final customer = result.customer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: ColorsCustom.secondaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: ColorsCustom.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      text: customer.fullName.isEmpty
                          ? customer.phone
                          : customer.fullName,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    TextCustom(
                      text: customer.phone,
                      fontSize: 13,
                      color: ColorsCustom.textSecondary,
                    ),
                  ],
                ),
              ),
              TextCustom(
                text: l10n.ordersCount(result.orders.length),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ColorsCustom.textHint,
              ),
            ],
          ),
        ),
        for (final order in result.orders)
          AdminOrderCard(
            order: order,
            onTap: () => context.pushNamed(
              AppRoutes.adminOrderDetailName,
              pathParameters: {'id': '${order.id}'},
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/message_dialog.dart';
import 'package:sapbaq_admin/core/widgets/reason_sheet.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_product.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/products_cubit.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/pill.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Product availability (§11): staff can temporarily suspend/hide a product
/// from customers (availability only — not catalog data, which is web-managed).
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProductsCubit(context.read<AdminRepository>())..load(),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatefulWidget {
  const _ProductsView();

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
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
      context.read<ProductsCubit>().loadMore();
    }
  }

  Future<void> _toggle(BuildContext context, AdminProduct p, bool value) async {
    final cubit = context.read<ProductsCubit>();
    final l10n = AppLocalizations.of(context)!;
    String? reason;
    if (!value) {
      // Suspending — optionally capture a reason (the field is optional, so an
      // empty confirm is fine; only a dismissal aborts).
      reason = await ReasonSheet.show(
        context,
        title: l10n.suspendReasonTitle,
        hint: l10n.suspendReasonHint,
        confirmLabel: l10n.suspendConfirm,
        accent: ColorsCustom.error,
      );
      if (reason == null) return;
    }
    await cubit.setAvailability(p.id, value, reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.productsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (q) => context.read<ProductsCubit>().search(q),
              decoration: InputDecoration(
                hintText: l10n.searchProductsHint,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.colors.textHint,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: context.colors.textHint,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductsCubit>().search('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<ProductsCubit, ProductsState>(
              listenWhen: (a, b) => a.message != b.message && b.message != null,
              listener: (context, state) =>
                  ShowMessage.error(context, state.message!),
              builder: (context, state) {
                if (state.status == LoadStatus.loading) {
                  return const LoadingView();
                }
                if (state.status == LoadStatus.failure) {
                  return ErrorView(
                    message: state.message ?? l10n.genericError,
                    retryLabel: l10n.retry,
                    onRetry: () => context.read<ProductsCubit>().load(),
                  );
                }
                if (state.items.isEmpty) {
                  return EmptyView(
                    message: l10n.emptyProducts,
                    icon: Icons.inventory_2_outlined,
                  );
                }
                return RefreshIndicator(
                  color: context.colors.primary,
                  onRefresh: () => context.read<ProductsCubit>().load(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= state.items.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: context.colors.primary,
                            ),
                          ),
                        );
                      }
                      final product = state.items[i];
                      return _ProductRow(
                        product: product,
                        busy: state.togglingId == product.id,
                        onChanged: (v) => _toggle(context, product, v),
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

class _ProductRow extends StatelessWidget {
  final AdminProduct product;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _ProductRow({
    required this.product,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: product.name,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (product.categoryName.isNotEmpty) ...[
                      Flexible(
                        child: TextCustom(
                          text: product.categoryName,
                          fontSize: 12,
                          color: context.colors.textHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextCustom(text: '·', color: context.colors.textHint),
                      const SizedBox(width: 6),
                    ],
                    TextCustom(
                      text: l10n.priceKwd(product.price),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.colors.primary,
                    ),
                  ],
                ),
                if (!product.isActive) ...[
                  const SizedBox(height: 6),
                  Pill(
                    text: l10n.productInactive,
                    color: context.colors.textSecondary,
                    background: context.colors.surfaceVariant,
                    fontSize: 10.5,
                  ),
                ] else if (!product.isAvailable) ...[
                  const SizedBox(height: 6),
                  Pill(
                    text: l10n.productSuspended,
                    color: ColorsCustom.error,
                    background: context.colors.surfaceVariant,
                    fontSize: 10.5,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (busy)
            SizedBox(
              width: 40,
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.primary,
                  ),
                ),
              ),
            )
          else
            Switch(
              value: product.isAvailable,
              // is_active is the permanent web-managed flag; can't toggle here.
              onChanged: product.isActive ? onChanged : null,
            ),
        ],
      ),
    );
  }
}

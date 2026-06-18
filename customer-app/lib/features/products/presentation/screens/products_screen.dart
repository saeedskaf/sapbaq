import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/cart/presentation/widgets/floating_cart_bar.dart';
import 'package:sapbaq/features/products/data/models/product.dart';
import 'package:sapbaq/features/products/data/models/product_category.dart';
import 'package:sapbaq/features/products/data/products_repository.dart';
import 'package:sapbaq/features/products/presentation/widgets/product_card.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Products for a chosen donation destination. Loads product categories,
/// renders them as equal-width text tabs, and a PageView underneath where
/// each page is a category-filtered grid that loads its own products
/// lazily. Tapping a product card opens the detail screen — cart actions
/// live there, not on the grid card.
class ProductsScreen extends StatefulWidget {
  final DonationDestination destination;

  const ProductsScreen({super.key, required this.destination});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  LoadStatus _status = LoadStatus.loading;
  List<ProductCategory> _categories = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final categories = await context
          .read<ProductsRepository>()
          .fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _status = LoadStatus.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = LoadStatus.failure;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: TextCustom(
          text: l10n.donatingTo(widget.destination.label),
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: BlocListener<CartCubit, CartState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, state) => ShowMessage.error(context, state.message!),
        child: switch (_status) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(),
          LoadStatus.failure => ErrorView(
            message: _error ?? l10n.comingSoon,
            retryLabel: l10n.retry,
            onRetry: _loadCategories,
          ),
          LoadStatus.success when _categories.isEmpty => _ProductsGrid(
            destination: widget.destination,
            categoryId: null,
          ),
          LoadStatus.success => _CategoriesPager(
            categories: _categories,
            destination: widget.destination,
          ),
        },
      ),
      bottomNavigationBar: const CartBar(safeAreaBottom: true),
    );
  }
}

/// Equal-width tab bar + PageView. Selected tab fills with the brand green;
/// swiping the page updates the selected tab and vice-versa.
class _CategoriesPager extends StatefulWidget {
  final List<ProductCategory> categories;
  final DonationDestination destination;

  const _CategoriesPager({required this.categories, required this.destination});

  @override
  State<_CategoriesPager> createState() => _CategoriesPagerState();
}

class _CategoriesPagerState extends State<_CategoriesPager> {
  late final PageController _pageController;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CategoryTabs(
          categories: widget.categories,
          selectedIndex: _selected,
          onSelected: _onTabTap,
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.categories.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) {
              return _ProductsGrid(
                key: ValueKey('cat-${widget.categories[i].id}'),
                destination: widget.destination,
                categoryId: widget.categories[i].id,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A single joined "segmented control" tab bar — one rounded container with
/// all categories sharing the same background; an animated pill slides
/// between segments to mark the selected one. No icons.
class _CategoryTabs extends StatelessWidget {
  final List<ProductCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _CategoryTabs({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final n = categories.length;
    if (n == 0) return const SizedBox.shrink();
    // -1 (start side) → +1 (end side), evenly spaced over the N segments.
    final pillAlignX = n == 1 ? 0.0 : (2 * selectedIndex / (n - 1)) - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            // Sliding pill — the selected segment's background. Sits behind
            // the labels so the row of taps stays one continuous control.
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: AlignmentDirectional(pillAlignX, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            // The labels — text only, equal-width tap targets across the row.
            Row(
              children: [
                for (int i = 0; i < n; i++)
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onSelected(i),
                        child: Center(
                          child: TextCustom(
                            text: categories[i].name,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: i == selectedIndex
                                ? ColorsCustom.textOnPrimary
                                : context.colors.textPrimary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Lazily-loaded products grid for one category (or unfiltered when
/// [categoryId] is null). Keeps its own products in memory so switching
/// tabs doesn't re-fetch.
class _ProductsGrid extends StatefulWidget {
  final int? categoryId;
  final DonationDestination destination;

  const _ProductsGrid({
    super.key,
    required this.categoryId,
    required this.destination,
  });

  @override
  State<_ProductsGrid> createState() => _ProductsGridState();
}

class _ProductsGridState extends State<_ProductsGrid>
    with AutomaticKeepAliveClientMixin {
  LoadStatus _status = LoadStatus.loading;
  List<Product> _products = const [];
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final products = await context
          .read<ProductsRepository>()
          .fetchProducts(categoryId: widget.categoryId);
      if (!mounted) return;
      setState(() {
        _products = products;
        _status = LoadStatus.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = LoadStatus.failure;
        _error = e.message;
      });
    }
  }

  void _openDetail(Product product) {
    context.pushNamed(
      AppRoutes.productDetailName,
      pathParameters: {'id': product.id.toString()},
      extra: widget.destination,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return switch (_status) {
      LoadStatus.initial || LoadStatus.loading => const LoadingView(),
      LoadStatus.failure => ErrorView(
        message: _error ?? l10n.comingSoon,
        retryLabel: l10n.retry,
        onRetry: _load,
      ),
      LoadStatus.success when _products.isEmpty => EmptyView(
        message: l10n.emptyProducts,
        icon: Icons.water_drop_outlined,
      ),
      LoadStatus.success => RefreshIndicator(
        color: context.colors.primary,
        onRefresh: _load,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            // Square image + name + 1-line desc + 1-line price + padding.
            // 0.60 leaves a few pixels of slack across 320-414 width
            // phones — fixes the bottom overflow that 0.65 produced.
            childAspectRatio: 0.60,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            return ProductCard(
              product: product,
              onTap: () => _openDetail(product),
            );
          },
        ),
      ),
    };
  }
}

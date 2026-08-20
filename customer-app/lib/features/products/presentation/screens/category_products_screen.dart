import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/presentation/widgets/floating_cart_bar.dart';
import 'package:sapbaq/features/home/presentation/widgets/destination_bar.dart';
import 'package:sapbaq/features/products/data/models/product.dart';
import 'package:sapbaq/features/products/data/models/product_category.dart';
import 'package:sapbaq/features/products/data/products_repository.dart';
import 'package:sapbaq/features/products/presentation/widgets/product_card.dart';
import 'package:sapbaq/features/products/presentation/widgets/product_detail_sheet.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The full products browser: the destination bar on top, category tabs to
/// switch between product types, and each tab's grid underneath.
///
/// Entries: «عرض المزيد» on a storefront shelf opens it on that category's tab
/// ([initialCategoryId]); a mosque's "donate to this mosque" opens it with the
/// destination preset and the first tab selected. Product taps open the
/// bottom-sheet quick view.
class CategoryProductsScreen extends StatefulWidget {
  final int? initialCategoryId;

  const CategoryProductsScreen({super.key, this.initialCategoryId});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
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

  int get _initialIndex {
    final i = _categories.indexWhere((c) => c.id == widget.initialCategoryId);
    return i == -1 ? 0 : i;
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
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        title: TextCustom(
          text: l10n.productsTitle,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DestinationBar(),
          ),
          Expanded(
            child: switch (_status) {
              LoadStatus.initial || LoadStatus.loading => const LoadingView(),
              LoadStatus.failure => ErrorView(
                message: _error ?? l10n.comingSoon,
                retryLabel: l10n.retry,
                onRetry: _loadCategories,
              ),
              LoadStatus.success when _categories.isEmpty =>
                const _ProductsGrid(categoryId: null),
              LoadStatus.success => _CategoriesPager(
                categories: _categories,
                initialIndex: _initialIndex,
              ),
            },
          ),
        ],
      ),
      bottomNavigationBar: const CartBar(safeAreaBottom: true),
    );
  }
}

/// Equal-width tab bar + PageView. Selected tab fills with the brand green;
/// swiping the page updates the selected tab and vice-versa.
class _CategoriesPager extends StatefulWidget {
  final List<ProductCategory> categories;
  final int initialIndex;

  const _CategoriesPager({
    required this.categories,
    required this.initialIndex,
  });

  @override
  State<_CategoriesPager> createState() => _CategoriesPagerState();
}

class _CategoriesPagerState extends State<_CategoriesPager> {
  late final PageController _pageController;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
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
/// between segments to mark the selected one.
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                    color: context.colors.primaryFill,
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
                                ? context.colors.onPrimary
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
/// [categoryId] is null). Keeps its products in memory so switching tabs
/// doesn't re-fetch.
class _ProductsGrid extends StatefulWidget {
  final int? categoryId;

  const _ProductsGrid({super.key, required this.categoryId});

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
      final products = await context.read<ProductsRepository>().fetchProducts(
        categoryId: widget.categoryId,
      );
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            // Square image + name + 1-line desc + price (same slack the old
            // products grid used on 320-414pt phones).
            childAspectRatio: 0.60,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            return ProductCard(
              product: product,
              onTap: () => showProductDetailSheet(context, product.id),
            );
          },
        ),
      ),
    };
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/products/data/models/product.dart';
import 'package:sapbaq/features/products/data/models/product_category.dart';
import 'package:sapbaq/features/products/data/products_repository.dart';
import 'package:sapbaq/features/products/presentation/widgets/product_card.dart';
import 'package:sapbaq/features/products/presentation/widgets/product_detail_sheet.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

// Shelf card geometry — mirrors the 0.60 grid aspect the catalogue uses, so
// cards look identical on shelves and grids.
const double _shelfCardWidth = 165;
const double _shelfHeight = _shelfCardWidth / 0.60;

/// How many products a shelf previews before «عرض المزيد» takes over.
const int _shelfPreviewCount = 10;

/// The storefront section of Home: one shelf per category — a section header
/// (name + «عرض المزيد» to the full category grid) over a horizontally
/// scrolling row of product cards. Tapping a card opens the product's
/// bottom-sheet quick view (adds go to the destination bar's cart).
class HomeStore extends StatefulWidget {
  const HomeStore({super.key});

  @override
  State<HomeStore> createState() => HomeStoreState();
}

class HomeStoreState extends State<HomeStore> {
  LoadStatus _categoriesStatus = LoadStatus.loading;
  List<ProductCategory> _categories = const [];
  String? _error;

  /// Per-section products, keyed by category id (null = the whole catalogue,
  /// used when the backend has no categories).
  final Map<int?, List<Product>> _products = {};
  final Map<int?, LoadStatus> _productsStatus = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesStatus = LoadStatus.loading);
    try {
      final categories = await context
          .read<ProductsRepository>()
          .fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoriesStatus = LoadStatus.success;
      });
      // All shelves are visible at once — fetch them in parallel.
      if (categories.isEmpty) {
        _loadProducts(null);
      } else {
        for (final category in categories) {
          _loadProducts(category.id);
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesStatus = LoadStatus.failure;
        _error = e.message;
      });
    }
  }

  Future<void> _loadProducts(int? categoryId) async {
    if (_productsStatus[categoryId] == LoadStatus.loading) return;
    setState(() => _productsStatus[categoryId] = LoadStatus.loading);
    try {
      final products = await context.read<ProductsRepository>().fetchProducts(
        categoryId: categoryId,
      );
      if (!mounted) return;
      setState(() {
        _products[categoryId] = products;
        _productsStatus[categoryId] = LoadStatus.success;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _productsStatus[categoryId] = LoadStatus.failure);
    }
  }

  /// Pull-to-refresh from the storefront: re-fetch categories and every shelf
  /// without tearing down the current content (no full-section spinner flash),
  /// and complete only once the shelves have reloaded.
  Future<void> reload() async {
    final repo = context.read<ProductsRepository>();
    try {
      final categories = await repo.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoriesStatus = LoadStatus.success;
        _error = null;
      });
      final Iterable<int?> ids = categories.isEmpty
          ? const <int?>[null]
          : categories.map((c) => c.id);
      await Future.wait([for (final id in ids) _loadProducts(id)]);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Only surface an error if there's nothing already on screen.
      if (_categories.isEmpty) {
        setState(() {
          _categoriesStatus = LoadStatus.failure;
          _error = e.message;
        });
      }
    }
  }

  void _openCategory(ProductCategory? category) {
    // Opens the tabbed products browser on this category's tab.
    context.pushNamed(AppRoutes.categoryProductsName, extra: category?.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_categoriesStatus) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const _BoxSliver(child: LoadingView());
      case LoadStatus.failure:
        return _BoxSliver(
          child: ErrorView(
            message: _error ?? l10n.comingSoon,
            retryLabel: l10n.retry,
            onRetry: _loadCategories,
          ),
        );
      case LoadStatus.success:
        if (_categories.isEmpty) {
          // No categories — a single shelf over the whole catalogue.
          return _ShelfSection(
            title: l10n.productsTitle,
            status: _productsStatus[null] ?? LoadStatus.loading,
            products: _products[null] ?? const [],
            onSeeMore: () => _openCategory(null),
            onRetry: () => _loadProducts(null),
          );
        }
        return SliverMainAxisGroup(
          slivers: [
            for (final category in _categories)
              _ShelfSection(
                title: category.name,
                status: _productsStatus[category.id] ?? LoadStatus.loading,
                products: _products[category.id] ?? const [],
                onSeeMore: () => _openCategory(category),
                onRetry: () => _loadProducts(category.id),
              ),
          ],
        );
    }
  }
}

/// One category section: header row + a horizontal shelf of product cards.
/// Empty categories render nothing; a failed shelf shows a compact retry.
class _ShelfSection extends StatelessWidget {
  final String title;
  final LoadStatus status;
  final List<Product> products;
  final VoidCallback onSeeMore;
  final VoidCallback onRetry;

  const _ShelfSection({
    required this.title,
    required this.status,
    required this.products,
    required this.onSeeMore,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // A loaded-but-empty category earns no space on the storefront.
    if (status == LoadStatus.success && products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextCustom.subheading(
                    text: title,
                    fontSize: 17,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onSeeMore,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextCustom(
                        text: l10n.seeMore,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: 2),
                      // Auto-mirrors under RTL.
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: context.colors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _shelf(context, l10n)),
      ],
    );
  }

  Widget _shelf(BuildContext context, AppLocalizations l10n) {
    switch (status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return SizedBox(
          height: _shelfHeight,
          child: Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          ),
        );
      case LoadStatus.failure:
        return SizedBox(
          height: 88,
          child: Center(
            child: TextButton.icon(
              onPressed: onRetry,
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: context.colors.primary,
              ),
              label: TextCustom(
                text: l10n.retry,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.colors.primary,
              ),
            ),
          ),
        );
      case LoadStatus.success:
        final preview = products.take(_shelfPreviewCount).toList();
        return SizedBox(
          height: _shelfHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: preview.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final product = preview[i];
              return SizedBox(
                width: _shelfCardWidth,
                child: ProductCard(
                  product: product,
                  onTap: () => showProductDetailSheet(context, product.id),
                ),
              );
            },
          ),
        );
    }
  }
}

/// A box child (loading/error view) presented as a fixed-height sliver.
class _BoxSliver extends StatelessWidget {
  final Widget child;
  const _BoxSliver({required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: SizedBox(height: 260, child: child));
  }
}

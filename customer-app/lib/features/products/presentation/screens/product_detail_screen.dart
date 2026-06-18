import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/auth/auth_guard.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/utils/media_url.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/in_app_media.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/data/models/cart.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/cart/presentation/widgets/floating_cart_bar.dart';
import 'package:sapbaq/features/products/data/models/product.dart';
import 'package:sapbaq/features/products/data/models/product_media.dart';
import 'package:sapbaq/features/products/data/products_repository.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Full-screen detail view for a single product. A tinted "frame" surrounds
/// the contained image, then one calm white sheet shows the name, price,
/// and description. A sticky bottom bar holds the add-to-cart action.
class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final DonationDestination destination;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.destination,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  LoadStatus _status = LoadStatus.loading;
  Product? _product;
  String? _error;

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
      final product = await context.read<ProductsRepository>().fetchProduct(
        widget.productId,
      );
      if (!mounted) return;
      setState(() {
        _product = product;
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

  CartItem? _cartItem(Cart cart, int productId) {
    for (final group in cart.groups) {
      final matches = widget.destination.isMostNeeded
          ? group.isMostNeeded
          : group.mosqueId == widget.destination.mosqueId;
      if (!matches) continue;
      for (final item in group.items) {
        if (item.productId == productId) return item;
      }
    }
    return null;
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
          text: l10n.productDetailsTitle,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
      ),
      body: BlocListener<CartCubit, CartState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, state) =>
            ShowMessage.error(context, state.message!),
        child: switch (_status) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(),
          LoadStatus.failure => ErrorView(
            message: _error ?? l10n.comingSoon,
            retryLabel: l10n.retry,
            onRetry: _load,
          ),
          LoadStatus.success => _ProductDetailContent(
            product: _product!,
            destination: widget.destination,
            cartItemFor: _cartItem,
          ),
        },
      ),
    );
  }
}

class _ProductDetailContent extends StatelessWidget {
  final Product product;
  final DonationDestination destination;
  final CartItem? Function(Cart, int) cartItemFor;

  const _ProductDetailContent({
    required this.product,
    required this.destination,
    required this.cartItemFor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (a, b) => a.cart != b.cart,
      builder: (context, cartState) {
        final cart = context.read<CartCubit>();
        final item = cartItemFor(cartState.cart, product.id);
        final qty = item?.quantity ?? 0;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProductGallery(
                      items: product.gallery,
                      badge: _discountBadge(product),
                    ),
                    const SizedBox(height: 20),
                    _InfoSheet(product: product, l10n: l10n),
                  ],
                ),
              ),
            ),
            // Cart bar above the action button — only shows when the cart
            // has items, hidden otherwise. The action button below handles
            // its own safe-area padding.
            const CartBar(),
            SafeArea(
              top: false,
              child: _ActionBar(
                l10n: l10n,
                quantity: qty,
                onAdd: () {
                  if (!ensureAuthenticated(context)) return;
                  cart.addItem(
                    productId: product.id,
                    quantity: 1,
                    destination: destination,
                  );
                },
                onIncrement: () {
                  if (item != null) {
                    cart.updateQuantity(item.itemId, qty + 1);
                  }
                },
                onDecrement: () {
                  if (item == null) return;
                  if (qty > 1) {
                    cart.updateQuantity(item.itemId, qty - 1);
                  } else {
                    cart.removeItem(item.itemId);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String? _discountBadge(Product product) {
    if (!product.hasDiscount) return null;
    if (product.discountLabel != null && product.discountLabel!.isNotEmpty) {
      return product.discountLabel;
    }
    if (product.discountPercent != null) return '-${product.discountPercent}%';
    return null;
  }
}

/// Swipeable gallery for the product detail: the cover image first, then any
/// extra images and videos — all opened in-app. Keeps the tinted square frame
/// and the discount badge of the original hero, with a dots indicator once
/// there is more than one item. Falls back to a single calm icon when the
/// product has no media at all.
class _ProductGallery extends StatefulWidget {
  final List<ProductMedia> items;
  final String? badge;

  const _ProductGallery({required this.items, required this.badge});

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (items.isEmpty)
                    Center(
                      child: Icon(
                        Icons.water_drop_outlined,
                        size: 72,
                        color: context.colors.textHint,
                      ),
                    )
                  else
                    PageView.builder(
                      itemCount: items.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) => _GalleryPage(media: items[i]),
                    ),
                  if (widget.badge != null)
                    PositionedDirectional(
                      top: 14,
                      start: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextCustom(
                          text: widget.badge!,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: ColorsCustom.textOnPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              items.length,
              (i) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index
                      ? context.colors.primary
                      : context.colors.border,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One page of the product gallery. Images are shown contained on the tinted
/// frame and tap to zoom; videos show their thumbnail (or a neutral fallback)
/// under a play badge and tap to play in-app.
class _GalleryPage extends StatelessWidget {
  final ProductMedia media;

  const _GalleryPage({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.isVideo) {
      final thumb = resolveMediaUrl(media.thumbnail);
      return GestureDetector(
        onTap: () => openInAppVideo(context, media.file),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumb != null)
              Image.network(
                thumb,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const MediaFallback(isVideo: true),
              )
            else
              const MediaFallback(isVideo: true),
            const Center(child: PlayBadge()),
          ],
        ),
      );
    }

    final url = resolveMediaUrl(media.file);
    if (url == null) return const MediaFallback(isVideo: false);
    return GestureDetector(
      onTap: () => openInAppImage(context, url: media.file),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.primary,
              ),
            );
          },
          errorBuilder: (_, _, _) => const MediaFallback(isVideo: false),
        ),
      ),
    );
  }
}

/// Single calm white sheet — name, price, then a divider and the
/// description. No nested cards, no extra shadows.
class _InfoSheet extends StatelessWidget {
  final Product product;
  final AppLocalizations l10n;

  const _InfoSheet({required this.product, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final hasDesc = product.description.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(
            text: product.name,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
          const SizedBox(height: 12),
          _PriceRow(product: product, l10n: l10n),
          if (hasDesc) ...[
            const SizedBox(height: 20),
            Divider(height: 1, color: context.colors.border),
            const SizedBox(height: 16),
            TextCustom(
              text: l10n.descriptionLabel,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
            const SizedBox(height: 8),
            TextCustom(
              text: product.description,
              fontSize: 14,
              color: context.colors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final Product product;
  final AppLocalizations l10n;

  const _PriceRow({required this.product, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextCustom(
          text: l10n.priceKwd(product.effectivePrice),
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: context.colors.primary,
        ),
        if (product.hasDiscount) ...[
          const SizedBox(width: 10),
          Padding(
            // The strike-through is rendered on the bare number (no "د.ك")
            // so its baseline lines up cleanly with the LTR digits — same
            // pattern the products grid card uses.
            padding: const EdgeInsets.only(bottom: 5),
            child: TextCustom(
              text: product.price,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.colors.textHint,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}

/// Sticky bottom action — primary "add to cart" button when nothing is in
/// the cart yet, or a quantity stepper once the product is in.
class _ActionBar extends StatelessWidget {
  final AppLocalizations l10n;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ActionBar({
    required this.l10n,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: quantity == 0
          ? ButtonCustom.primary(
              text: l10n.addToCart,
              icon: const Icon(
                Icons.add_shopping_cart_rounded,
              ),
              onPressed: onAdd,
            )
          : _StepperBar(
              quantity: quantity,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
    );
  }
}

class _StepperBar extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _StepperBar({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.primary,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            _StepButton(
              icon: quantity > 1
                  ? Icons.remove_rounded
                  : Icons.delete_outline_rounded,
              onTap: onDecrement,
            ),
            Expanded(
              child: Center(
                child: TextCustom(
                  text: '$quantity',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onPrimary,
                ),
              ),
            ),
            _StepButton(icon: Icons.add_rounded, onTap: onIncrement),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Icon(icon, size: 22, color: context.colors.onPrimary),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/auth/auth_guard.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/message_dialog.dart';
import 'package:sapbaq/core/widgets/price_text.dart';
import 'package:sapbaq/core/widgets/sheet_header.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/cart/data/models/cart.dart';
import 'package:sapbaq/features/cart/data/models/donation_destination.dart';
import 'package:sapbaq/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:sapbaq/features/cart/presentation/widgets/dedication_sheet.dart';
import 'package:sapbaq/features/cart/presentation/widgets/destination_picker_sheet.dart';
import 'package:sapbaq/core/widgets/image_carousel.dart';
import 'package:sapbaq/features/equipment/presentation/screens/equipment_request_form_screen.dart';
import 'package:sapbaq/features/products/data/models/product.dart';
import 'package:sapbaq/features/products/data/models/product_option.dart';
import 'package:sapbaq/features/products/data/products_repository.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Quick-view product details as a draggable bottom sheet (instead of a pushed
/// page): gallery, name/price/description, and the add-to-cart action. Adds go
/// to the destination bar's cart; if no destination is set yet, the picker
/// prompts first.
Future<void> showProductDetailSheet(BuildContext context, int productId) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => _ProductDetailSheet(
        productId: productId,
        scrollController: scrollController,
      ),
    ),
  );
}

class _ProductDetailSheet extends StatefulWidget {
  final int productId;
  final ScrollController scrollController;

  const _ProductDetailSheet({
    required this.productId,
    required this.scrollController,
  });

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
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

  CartItem? _cartItem(
    List<DonationCart> carts,
    int productId,
    int? variantId,
    DonationDestination? dest,
  ) {
    if (dest == null) return null;
    for (final cart in carts) {
      // The mosque is the cart's identity — "most needed" is only a tag on it
      // now, so matching on that tag would pick any other tagged mosque's cart.
      if (cart.mosqueId != dest.mosqueId) continue;
      for (final item in cart.items) {
        // Variants of one product are separate lines — the stepper must track
        // the (product + variant) line, not just the product.
        if (item.productId == productId && item.variantId == variantId) {
          return item;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: BlocListener<CartCubit, CartState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, state) =>
            ShowMessage.error(context, state.message!),
        child: Column(
          children: [
            const SheetHandleBar(),
            Expanded(
              child: switch (_status) {
                LoadStatus.initial || LoadStatus.loading => const LoadingView(),
                LoadStatus.failure => ErrorView(
                  message: _error ?? l10n.comingSoon,
                  retryLabel: l10n.retry,
                  onRetry: _load,
                ),
                LoadStatus.success => _SheetContent(
                  product: _product!,
                  scrollController: widget.scrollController,
                  cartItemFor: _cartItem,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetContent extends StatefulWidget {
  final Product product;
  final ScrollController scrollController;
  final CartItem? Function(List<DonationCart>, int, int?, DonationDestination?)
  cartItemFor;

  const _SheetContent({
    required this.product,
    required this.scrollController,
    required this.cartItemFor,
  });

  @override
  State<_SheetContent> createState() => _SheetContentState();
}

class _SheetContentState extends State<_SheetContent> {
  /// Picked option values, at most one per axis. Deliberately starts empty:
  /// the choice changes the price, so the customer must make it — the action
  /// stays disabled until every axis is answered (delivery §1.2).
  final Set<int> _selected = {};

  /// Transient "added ✓" strip for dedication products, whose Add button never
  /// morphs into a stepper (each add is its own line) — without this there is
  /// no visible confirmation at all, since the floating cart bar sits behind
  /// the modal sheet.
  bool _showAdded = false;
  Timer? _addedTimer;

  @override
  void dispose() {
    _addedTimer?.cancel();
    super.dispose();
  }

  void _flashAdded() {
    _addedTimer?.cancel();
    setState(() => _showAdded = true);
    _addedTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showAdded = false);
    });
  }

  /// Replaces this axis's previous pick, then drops any now-impossible picks on
  /// the axes that follow — choosing a colour that only comes in L must not
  /// leave a stale "M" selected behind it.
  void _pick(ProductOptionType axis, ProductOptionValue value) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected.removeAll(axis.values.map((v) => v.id));
      _selected.add(value.id);
      for (final other in widget.product.optionTypes) {
        if (other.id == axis.id) continue;
        final selectable = widget.product.selectableValueIds(other, _selected);
        _selected.removeWhere(
          (id) =>
              other.values.any((v) => v.id == id) && !selectable.contains(id),
        );
      }
    });
  }

  /// The image the gallery opens on. The contract's order of specificity
  /// (delivery §1.5) — the picked combination's own image, then the picked
  /// value's — with one addition: while the selection is still **partial** and
  /// neither of those exists, the first available combination the picks lead to
  /// stands in for them. Without it the gallery would sit on the cover until the
  /// last axis is answered, since a value-level image is optional and the
  /// dashboard rarely fills it in.
  ///
  /// Null means "nothing more specific than the product itself" — the gallery
  /// then shows unchanged.
  String? get _heroImage {
    final product = widget.product;
    final variant = product.variantFor(_selected);
    if (variant?.image != null) return variant!.image;
    for (final axis in product.optionTypes) {
      for (final value in axis.values) {
        if (_selected.contains(value.id) && value.hasImage) return value.image;
      }
    }
    return product.representativeImage(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final product = widget.product;
    final variant = product.variantFor(_selected);
    final hero = _heroImage;
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (a, b) =>
          a.carts != b.carts || a.currentDestination != b.currentDestination,
      builder: (context, cartState) {
        final cart = context.read<CartCubit>();
        final dest = cartState.currentDestination;
        final needsVariant = product.hasVariants && variant == null;
        // Dedication products carry a per-line name, so several lines of the
        // same product can coexist — never collapse to a stepper; always offer
        // "Add" and manage the individual lines from the cart. Approval
        // products are requested one unit at a time, so no stepper there either.
        final item =
            product.supportsDedication || needsVariant || product.isApproval
            ? null
            : widget.cartItemFor(
                cartState.carts,
                product.id,
                variant?.id,
                dest,
              );
        final qty = item?.quantity ?? 0;
        // The destination's whole cart — feeds the "view cart" line, which is
        // the only cart affordance visible while this modal covers the
        // floating cart bar.
        DonationCart? destCart;
        if (dest != null) {
          for (final c in cartState.carts) {
            // Matched by mosque only — "most needed" is a tag on the mosque,
            // not a cart of its own.
            if (c.mosqueId == dest.mosqueId) {
              destCart = c;
              break;
            }
          }
        }
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cross-fades between selections: the carousel is rebuilt on
                    // every new hero (that is what rewinds it to page one), and
                    // without the fade that rebuild reads as a jump cut.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: ImageCarousel.media(
                        // Keyed on the override so picking a colour rewinds the
                        // carousel to that colour's photo instead of leaving the
                        // customer on page 3 of the old one.
                        key: ValueKey(hero),
                        media: [
                          if (hero != null) CarouselMedia.image(hero),
                          for (final m in product.gallery)
                            if (m.isVideo)
                              CarouselMedia.video(
                                m.file,
                                thumbnail: m.thumbnail,
                              )
                            // The hero leads the gallery; showing it a second
                            // time in place would duplicate it in the thumbnail
                            // strip too.
                            else if (m.file != hero)
                              CarouselMedia.image(m.file),
                        ],
                        aspectRatio: 1.15,
                        borderRadius: 20,
                        padding: 28,
                        placeholderIcon: Icons.water_drop_outlined,
                        showThumbnails: true,
                        badge: _badge(context, _discountBadge(product)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InfoSheet(
                      product: product,
                      l10n: l10n,
                      variant: variant,
                      selected: _selected,
                      onPick: _pick,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AddedFlash(visible: _showAdded, l10n: l10n),
                  if (destCart != null && destCart.itemCount > 0)
                    _CartSummaryRow(cart: destCart, l10n: l10n),
                  _ActionBar(
                    l10n: l10n,
                    quantity: qty,
                    enabled: !needsVariant && product.isAvailable,
                    unavailable: !product.isAvailable,
                    isApproval: product.isApproval,
                    lineTotal: item?.lineTotal,
                    onAdd: () async {
                      if (!ensureAuthenticated(context)) return;
                      // Both paths need a mosque; prompt the picker when no
                      // destination is set yet, then it sticks.
                      var target = dest;
                      if (target == null) {
                        final picked = await showDestinationPicker(context);
                        if (picked == null || !context.mounted) return;
                        cart.selectDestination(picked);
                        target = picked;
                      }
                      // The approval path never touches the cart: it opens the
                      // request form, and payment waits for a manager.
                      if (product.isApproval) {
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        context.pushNamed(
                          AppRoutes.equipmentRequestFormName,
                          extra: EquipmentRequestArgs(
                            product: product,
                            variant: variant,
                            destination: target,
                          ),
                        );
                        return;
                      }
                      // A dedication product asks for the engraving first; the
                      // donor may opt out, which comes back as an empty name.
                      Dedication? dedication;
                      if (product.supportsDedication) {
                        dedication = await showDedicationSheet(context);
                        if (dedication == null || !context.mounted) return;
                      }
                      final hasName = dedication?.name.isNotEmpty ?? false;
                      final added = await cart.addItem(
                        productId: product.id,
                        quantity: 1,
                        destination: target,
                        variantId: variant?.id,
                        dedicationName: hasName ? dedication!.name : null,
                        dedicationStatus: hasName ? dedication!.status : null,
                      );
                      if (!added || !mounted) return;
                      HapticFeedback.lightImpact();
                      // Ordinary products confirm themselves — the button
                      // morphs into the stepper. Dedication lines don't.
                      if (product.supportsDedication) _flashAdded();
                    },
                    onIncrement: () {
                      if (item != null) {
                        HapticFeedback.selectionClick();
                        cart.updateQuantity(item.itemId, qty + 1);
                      }
                    },
                    onDecrement: () {
                      if (item == null) return;
                      HapticFeedback.selectionClick();
                      if (qty > 1) {
                        cart.updateQuantity(item.itemId, qty - 1);
                      } else {
                        cart.removeItem(item.itemId);
                      }
                    },
                  ),
                ],
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

  /// The discount chip handed to the gallery's badge slot.
  Widget? _badge(BuildContext context, String? text) {
    if (text == null) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextCustom(
        text: text,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: context.colors.textSecondary,
      ),
    );
  }
}

/// Transient confirmation strip above the action bar («تمت الإضافة ✓»).
/// Rendered inline rather than as a SnackBar: the app's Scaffold — and its
/// snack bars — sit *behind* this modal sheet.
class _AddedFlash extends StatelessWidget {
  final bool visible;
  final AppLocalizations l10n;

  const _AddedFlash({required this.visible, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, child: child),
      ),
      child: !visible
          ? const SizedBox(width: double.infinity, key: ValueKey('flash-off'))
          : Padding(
              key: const ValueKey('flash-on'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: 8),
                    TextCustom(
                      text: l10n.addedToCart,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: context.colors.primary,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// One-line cart summary + «عرض السلة» inside the sheet — the floating cart
/// bar is covered by the modal, so this is the donor's path to checkout
/// without hunting for it after dismissing.
class _CartSummaryRow extends StatelessWidget {
  final DonationCart cart;
  final AppLocalizations l10n;

  const _CartSummaryRow({required this.cart, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            context.pushNamed(AppRoutes.cartName);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 17,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextCustom(
                    text:
                        '${l10n.inCartCount(cart.itemCount)} · '
                        '${l10n.priceKwd(cart.totalAmount)}',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextCustom(
                  text: l10n.viewCart,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.colors.primary,
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single calm sheet — name, price, variant picker (when the product has
/// variants), then a divider and the description.
class _InfoSheet extends StatelessWidget {
  final Product product;
  final AppLocalizations l10n;
  final ProductVariant? variant;
  final Set<int> selected;
  final void Function(ProductOptionType, ProductOptionValue) onPick;

  const _InfoSheet({
    required this.product,
    required this.l10n,
    required this.variant,
    required this.selected,
    required this.onPick,
  });

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
          if (product.isApproval) ...[
            const SizedBox(height: 10),
            _ApprovalNote(product: product, l10n: l10n),
          ],
          const SizedBox(height: 12),
          _PriceRow(product: product, l10n: l10n, variant: variant),
          // One row per axis, in the server's order — that order *is* the
          // order the customer picks in (delivery §1.2 rule 1).
          for (final axis in product.optionTypes) ...[
            const SizedBox(height: 16),
            _AxisRow(
              axis: axis,
              selected: selected,
              selectable: product.selectableValueIds(axis, selected),
              onPick: (value) => onPick(axis, value),
            ),
          ],
          if (variant != null && variant!.attributesDisplay.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final spec in variant!.attributesDisplay)
              if (spec.isRenderable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      TextCustom(
                        text: spec.label,
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextCustom(
                          text: spec.value,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
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
  final ProductVariant? variant;

  const _PriceRow({
    required this.product,
    required this.l10n,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    // The price follows the picked variant (variants doc §2): its effective
    // price once picked, "from <cheapest>" before that, and the base product
    // price only for ordinary products.
    final v = variant;
    // Before a pick, the server's own range decides the wording — a single
    // price when it doesn't vary, "from …" when it does.
    final showRange = v == null && product.hasPriceRange;
    final effective = v?.effectivePrice ?? product.priceFrom;
    final struck = v == null
        ? (product.hasVariants ? null : product.price)
        : v.price;
    final hasDiscount = v?.hasDiscount ?? product.hasDiscount;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        TextCustom(
          text: showRange
              ? l10n.priceFromKwd(effective)
              : l10n.priceKwd(effective),
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: context.colors.primary,
        ),
        if (hasDiscount && struck != null) ...[
          const SizedBox(width: 10),
          StruckPrice(amount: struck, fontSize: 16),
        ],
      ],
    );
  }
}

/// A short note under the name of an approval product: nothing is charged now,
/// and the payment window opens once a manager approves. The window length is a
/// dashboard setting — read, never hard-coded.
class _ApprovalNote extends StatelessWidget {
  final Product product;
  final AppLocalizations l10n;

  const _ApprovalNote({required this.product, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.verified_outlined,
          size: 16,
          color: context.colors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextCustom(
            text: l10n.equipNoteUnderReview(
              product.approval?.payWindowHours ?? 48,
            ),
            fontSize: 12,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// One axis of choice — its name, the picked value, and a wrapping row of its
/// values. A value with no available combination behind it (given the picks on
/// the other axes) is shown **disabled, never hidden**: the customer needs to
/// see that it exists (delivery §1.2 rules 3–4).
class _AxisRow extends StatelessWidget {
  final ProductOptionType axis;
  final Set<int> selected;
  final Set<int> selectable;
  final ValueChanged<ProductOptionValue> onPick;

  const _AxisRow({
    required this.axis,
    required this.selected,
    required this.selectable,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final picked = axis.values
        .where((v) => selected.contains(v.id))
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextCustom(
              text: axis.name,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
            if (picked != null) ...[
              const SizedBox(width: 6),
              Expanded(
                child: TextCustom(
                  text: '· ${picked.value}',
                  fontSize: 13,
                  color: context.colors.textSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in axis.values)
              _OptionChip(
                value: value,
                display: axis.display,
                selected: selected.contains(value.id),
                enabled: selectable.contains(value.id),
                onTap: () => onPick(value),
              ),
          ],
        ),
      ],
    );
  }
}

/// One value chip: a colour swatch, a thumbnail, or plain text.
///
/// The contract's order is image → swatch → text (delivery §1.2 rule 8), and
/// that still holds on chip and dropdown axes. A **swatch axis is pinned to its
/// disc**, though: it exists to show the colour beside the colour's name, and a
/// photo of the whole unit answers a different question. The value's image is
/// still used there when the dashboard left the swatch empty — an empty circle
/// would say nothing at all.
class _OptionChip extends StatelessWidget {
  final ProductOptionValue value;

  /// How the axis presents its values — decides whether the disc is pinned.
  final OptionDisplay display;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _OptionChip({
    required this.value,
    required this.display,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pinSwatch = display == OptionDisplay.swatch && value.hasSwatch;
    final image = !pinSwatch && value.hasImage ? value.image : null;
    final borderColor = selected
        ? ColorsCustom.brandMint
        : context.colors.border;
    final textColor = !enabled
        ? context.colors.textHint
        : selected
        ? ColorsCustom.onMint
        : context.colors.textPrimary;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.fromLTRB(image != null ? 6 : 14, 8, 14, 8),
          decoration: BoxDecoration(
            color: selected ? ColorsCustom.brandMint : context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 34,
                    height: 34,
                    // The same photo well the gallery uses, so a shot on white
                    // sits on white in both themes. `ContainedImage` insets by
                    // 10 unless told otherwise — at this size that would leave
                    // almost nothing of the photo.
                    color: context.colors.imageWell,
                    child: ContainedImage(
                      url: image,
                      padding: 2,
                      placeholderSize: 16,
                      placeholderIcon: Icons.water_drop_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (value.hasSwatch) ...[
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _swatchColor(value.swatchHex),
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.border),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              TextCustom(
                text: value.value,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textColor,
                decoration: enabled ? null : TextDecoration.lineThrough,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "#RRGGBB" → a colour; anything unparseable falls back to transparent, so a
  /// malformed swatch degrades to an empty circle rather than a crash.
  static Color _swatchColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null || cleaned.length != 6) return Colors.transparent;
    return Color(0xFF000000 | value);
  }
}

/// Sticky bottom action — primary "add to cart" button when nothing is in the
/// destination's cart yet, or a quantity stepper once the product is in.
/// [enabled] is false while a variant product awaits its pick — the choice
/// sets the price, so adding first would be adding an unpriced line.
class _ActionBar extends StatelessWidget {
  final AppLocalizations l10n;
  final int quantity;
  final bool enabled;

  /// Sold-out state — its own disabled wording, not the variant prompt.
  final bool unavailable;

  /// Approval products are requested for a mosque, not added to a cart — the
  /// wording and the icon both change (delivery §3).
  final bool isApproval;

  /// The cart line's running total, shown inside the stepper so quantity
  /// changes price the donation live.
  final String? lineTotal;

  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ActionBar({
    required this.l10n,
    required this.quantity,
    required this.enabled,
    required this.unavailable,
    required this.isApproval,
    required this.lineTotal,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: quantity == 0
          ? ButtonCustom.primary(
              text: unavailable
                  ? l10n.notAvailableNow
                  : !enabled
                  ? l10n.variantPickFirst
                  : isApproval
                  ? l10n.requestForMosque
                  : l10n.addToCart,
              icon: Icon(
                isApproval
                    ? Icons.mosque_rounded
                    : Icons.add_shopping_cart_rounded,
              ),
              onPressed: enabled ? onAdd : null,
            )
          : _StepperBar(
              quantity: quantity,
              lineTotal: lineTotal == null ? null : l10n.priceKwd(lineTotal!),
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
    );
  }
}

class _StepperBar extends StatelessWidget {
  final int quantity;

  /// Already-formatted line total (e.g. «7.500 د.ك»); hidden when null.
  final String? lineTotal;

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _StepperBar({
    required this.quantity,
    required this.lineTotal,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.primaryFill,
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
            SizedBox(
              width: 44,
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
            Expanded(
              child: lineTotal == null
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 18),
                        child: TextCustom(
                          text: lineTotal!,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.colors.onPrimary,
                        ),
                      ),
                    ),
            ),
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

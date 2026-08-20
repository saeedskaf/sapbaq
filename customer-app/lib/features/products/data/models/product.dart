import 'package:equatable/equatable.dart';
import 'package:sapbaq/features/products/data/models/product_media.dart';
import 'package:sapbaq/features/products/data/models/product_option.dart';

/// How a product is bought (delivery §1). The two paths differ only in
/// sequence — the catalogue, the variants and the dedication are shared.
enum FulfilmentType {
  /// Add to cart → checkout → pay now.
  cart,

  /// Request for a mosque → a manager approves → a payment window opens.
  approval;

  static FulfilmentType from(String? raw) => raw?.toUpperCase() == 'APPROVAL'
      ? FulfilmentType.approval
      : FulfilmentType.cart;
}

/// The extra facts an [FulfilmentType.approval] product carries. Present only
/// for that path — `null` otherwise.
class ProductApproval extends Equatable {
  /// How long the payment window stays open once a manager approves. A dashboard
  /// setting: read it, never hard-code 48 (delivery §1.3).
  final int payWindowHours;

  final int? equipmentTypeId;
  final String equipmentType;

  const ProductApproval({
    this.payWindowHours = 48,
    this.equipmentTypeId,
    this.equipmentType = '',
  });

  factory ProductApproval.fromJson(Map<String, dynamic> j) => ProductApproval(
    payWindowHours: j['pay_window_hours'] as int? ?? 48,
    equipmentTypeId: j['equipment_type_id'] as int?,
    equipmentType: (j['equipment_type'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [payWindowHours, equipmentTypeId, equipmentType];
}

/// One sellable combination of a product's option values — the SKU. Carries
/// exactly one value from every option type, and the server composes [name]
/// ("أسود — M") so the same wording appears in the cart, the order, the driver
/// app, the notification and the invoice (delivery §1.2 rule 6).
class ProductVariant extends Equatable {
  final int id;
  final String sku;
  final String name;

  /// The picked values, one per axis. Compare as a **set** — the server sorts
  /// them ascending, but the app must not depend on ordering.
  final List<int> optionValueIds;

  final String price; // variant list price
  final String effectivePrice; // after the product's discount — show this
  final bool hasDiscount;

  /// false → shown disabled, never hidden (delivery §1.2 rule 4).
  final bool isAvailable;

  final int sortOrder;

  /// Overrides the picked value's image when set; may be null.
  final String? image;

  /// Operational id of the unit this combination maps to. Display/trace only —
  /// never send it in a request (delivery §1.3).
  final int? equipmentModelId;

  final List<ProductAttribute> attributesDisplay;

  const ProductVariant({
    required this.id,
    this.sku = '',
    this.name = '',
    this.optionValueIds = const [],
    this.price = '0',
    this.effectivePrice = '0',
    this.hasDiscount = false,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.image,
    this.equipmentModelId,
    this.attributesDisplay = const [],
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    id: json['id'] as int? ?? 0,
    sku: (json['sku'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    optionValueIds: (json['option_value_ids'] as List<dynamic>? ?? const [])
        .map((e) => e as int)
        .toList(growable: false),
    price: (json['price'] ?? '0').toString(),
    effectivePrice: (json['effective_price'] ?? json['price'] ?? '0')
        .toString(),
    hasDiscount: json['has_discount'] as bool? ?? false,
    isAvailable: json['is_available'] as bool? ?? true,
    sortOrder: json['sort_order'] as int? ?? 0,
    image: (json['image'] as String?)?.isEmpty ?? true
        ? null
        : json['image'] as String,
    equipmentModelId: json['equipment_model_id'] as int?,
    attributesDisplay: ProductAttribute.listFrom(json['attributes_display']),
  );

  @override
  List<Object?> get props => [
    id,
    name,
    optionValueIds,
    price,
    effectivePrice,
    isAvailable,
    image,
  ];
}

/// A purchasable product. Prices are money strings — kept as strings to
/// preserve precision for display; the backend serializes **two** decimals
/// (its `MoneyField`), and the app never re-formats them.
///
/// Two shapes arrive from the server (delivery §1.1): the list shape omits
/// [optionTypes], [variants] and [media]; the detail shape
/// (`GET /products/{id}/`) carries everything. Both parse here — the omitted
/// fields simply stay empty. [description] is in both since 2026-08-06 — the
/// same untruncated text from the same serializer, `''` (never null) when the
/// product has none.
class Product extends Equatable {
  final int id;
  final String name;
  final String description;
  final String price; // original/list price
  final String effectivePrice; // price after discount — show this to the user

  /// Cheapest and dearest **available** variant, already discounted. Equal when
  /// there's one price; differ → show "from …". The server owns both; never
  /// derive them from [variants], which the list shape doesn't carry.
  final String priceFrom;
  final String priceTo;

  final bool hasDiscount;
  final String? discountLabel; // e.g. "تخفيضات رمضان"
  final String? discountPercent; // populated only for PERCENT-type discounts
  final String? image; // cover image — used in lists and cards
  final List<ProductMedia> media; // extra images + video for the detail gallery
  final int? categoryId;

  final FulfilmentType fulfilmentType;

  /// Set for the approval path only.
  final ProductApproval? approval;

  /// Every non-live order lands on a specific mosque now, so this is `true`
  /// throughout; kept because the contract carries it. Don't branch on it.
  final bool requiresMosque;

  /// When true the add-to-cart flow offers an *optional* dedication (status
  /// first, then the name). False → the customer never sees any trace of it.
  final bool supportsDedication;

  /// Computed server-side: false when every variant is unavailable, even if the
  /// product itself is active (delivery §1.1).
  final bool isAvailable;

  /// Variants and their axes, server-sorted. When [hasVariants] is true the
  /// customer must pick a full combination before the price is known.
  final bool hasVariants;
  final List<ProductOptionType> optionTypes;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.effectivePrice,
    String? priceFrom,
    String? priceTo,
    this.hasDiscount = false,
    this.discountLabel,
    this.discountPercent,
    this.image,
    this.media = const [],
    this.categoryId,
    this.fulfilmentType = FulfilmentType.cart,
    this.approval,
    this.requiresMosque = true,
    this.supportsDedication = false,
    this.isAvailable = true,
    this.hasVariants = false,
    this.optionTypes = const [],
    this.variants = const [],
  }) : priceFrom = priceFrom ?? effectivePrice,
       priceTo = priceTo ?? effectivePrice;

  bool get isApproval => fulfilmentType == FulfilmentType.approval;

  /// True when the card should read "from …" rather than a single price.
  bool get hasPriceRange => priceFrom != priceTo;

  /// Unified gallery for the detail carousel: the cover [image] first (when
  /// present), then the [media] items in their server-provided order. The
  /// cover is not duplicated inside [media], so it appears exactly once.
  List<ProductMedia> get gallery => [
    if (image != null && image!.isNotEmpty)
      ProductMedia(id: -1, mediaType: 'IMAGE', file: image!, sortOrder: -1),
    ...media,
  ];

  /// The variant matching a complete [selection] of option values, or null
  /// while the selection is still partial (or names a combination the admin
  /// never created — gaps are allowed, delivery §1.2 rule 3).
  ProductVariant? variantFor(Set<int> selection) {
    if (selection.length != optionTypes.length) return null;
    for (final variant in variants) {
      if (variant.optionValueIds.length == selection.length &&
          selection.containsAll(variant.optionValueIds)) {
        return variant;
      }
    }
    return null;
  }

  /// The photo that stands for a **partial** selection: the first available
  /// combination, in the server's order, that contains everything picked so far
  /// and carries an image. Picking "أسود" therefore shows the black unit at
  /// once, instead of leaving the cover up until the last axis is answered —
  /// the behaviour every large storefront has.
  ///
  /// Returns the image and nothing else on purpose: a partial selection has no
  /// price and no id to send, so no caller may reach the variant behind it.
  String? representativeImage(Set<int> selection) {
    if (selection.isEmpty) return null;
    for (final variant in variants) {
      if (!variant.isAvailable || variant.image == null) continue;
      if (variant.optionValueIds.toSet().containsAll(selection)) {
        return variant.image;
      }
    }
    return null;
  }

  /// Which values of [axis] can still be picked given everything chosen on the
  /// *other* axes. A value with no available combination behind it is offered
  /// disabled — progressive narrowing, the standard storefront behaviour.
  Set<int> selectableValueIds(ProductOptionType axis, Set<int> selection) {
    final otherAxisIds = {
      for (final type in optionTypes)
        if (type.id != axis.id)
          for (final value in type.values) value.id,
    };
    final fixed = selection.intersection(otherAxisIds);
    final selectable = <int>{};
    for (final variant in variants) {
      if (!variant.isAvailable) continue;
      final ids = variant.optionValueIds.toSet();
      if (!ids.containsAll(fixed)) continue;
      for (final value in axis.values) {
        if (ids.contains(value.id)) selectable.add(value.id);
      }
    }
    return selectable;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final discount = json['discount'];
    String? label;
    String? percent;
    if (discount is Map) {
      final d = Map<String, dynamic>.from(discount);
      final rawLabel = d['label'] as String?;
      if (rawLabel != null && rawLabel.isNotEmpty) label = rawLabel;
      if ((d['discount_type'] as String?) == 'PERCENT') {
        final value = double.tryParse((d['value'] ?? '').toString());
        if (value != null) {
          percent = value % 1 == 0
              ? value.toStringAsFixed(0)
              : value.toString();
        }
      }
    }
    final effective = (json['effective_price'] ?? json['price'] ?? '0')
        .toString();
    return Product(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] ?? '0').toString(),
      effectivePrice: effective,
      priceFrom: (json['price_from'] ?? effective).toString(),
      priceTo: (json['price_to'] ?? effective).toString(),
      hasDiscount: json['has_discount'] as bool? ?? false,
      discountLabel: label,
      discountPercent: percent,
      image: json['image'] as String?,
      media: (json['media'] as List<dynamic>? ?? const [])
          .map(
            (m) => ProductMedia.fromJson(Map<String, dynamic>.from(m as Map)),
          )
          .toList(growable: false),
      categoryId: json['category_id'] as int?,
      fulfilmentType: FulfilmentType.from(json['fulfilment_type'] as String?),
      approval: json['approval'] is Map
          ? ProductApproval.fromJson(
              Map<String, dynamic>.from(json['approval'] as Map),
            )
          : null,
      requiresMosque: json['requires_mosque'] as bool? ?? true,
      supportsDedication: json['supports_dedication'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      hasVariants: json['has_variants'] as bool? ?? false,
      optionTypes: (json['option_types'] as List<dynamic>? ?? const [])
          .map(
            (t) =>
                ProductOptionType.fromJson(Map<String, dynamic>.from(t as Map)),
          )
          .toList(growable: false),
      variants: (json['variants'] as List<dynamic>? ?? const [])
          .map(
            (v) => ProductVariant.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    effectivePrice,
    priceFrom,
    priceTo,
    hasDiscount,
    media,
    categoryId,
    fulfilmentType,
    isAvailable,
    optionTypes,
    variants,
  ];
}

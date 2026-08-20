import 'package:equatable/equatable.dart';

/// One choosable value on an axis — "حوضان", "خشب فاخر".
class OptionValue extends Equatable {
  final int id;
  final String value;
  final int sortOrder;

  const OptionValue({required this.id, this.value = '', this.sortOrder = 0});

  factory OptionValue.fromJson(Map<String, dynamic> j) => OptionValue(
    id: j['id'] as int? ?? 0,
    value: (j['value'] ?? '').toString(),
    sortOrder: j['sort_order'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [id, value, sortOrder];
}

/// One axis of choice on an equipment product — "عدد الأحواض", "التصميم".
/// Server-sorted; that order is the order the manager picks in.
class OptionType extends Equatable {
  final int id;
  final String name;
  final List<OptionValue> values;

  const OptionType({required this.id, this.name = '', this.values = const []});

  factory OptionType.fromJson(Map<String, dynamic> j) => OptionType(
    id: j['id'] as int? ?? 0,
    name: (j['name'] ?? '').toString(),
    values: (j['values'] as List<dynamic>? ?? const [])
        .map((v) => OptionValue.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList(growable: false),
  );

  @override
  List<Object?> get props => [id, name, values];
}

/// One sellable combination. [price] is the money string that becomes the
/// request's `target_amount`, so the manager sees the goal he is publishing.
class EquipmentVariant extends Equatable {
  final int id;
  final String name;
  final String price;
  final String effectivePrice;
  final bool isAvailable;
  final List<int> optionValueIds;
  final String image;

  const EquipmentVariant({
    required this.id,
    this.name = '',
    this.price = '',
    String? effectivePrice,
    this.isAvailable = true,
    this.optionValueIds = const [],
    this.image = '',
  }) : effectivePrice = effectivePrice ?? price;

  factory EquipmentVariant.fromJson(Map<String, dynamic> j) {
    final price = (j['price'] ?? '').toString();
    return EquipmentVariant(
      id: j['id'] as int? ?? 0,
      name: (j['name'] ?? '').toString(),
      price: price,
      effectivePrice: (j['effective_price'] ?? price).toString(),
      isAvailable: j['is_available'] as bool? ?? true,
      optionValueIds: (j['option_value_ids'] as List<dynamic>? ?? const [])
          .map((e) => e as int)
          .toList(growable: false),
      image: (j['image'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, price, isAvailable, optionValueIds];
}

/// An equipment product as the approval and direct-provision pickers read it —
/// the **same serializer the customer app gets** (delivery §6.3), so the chips
/// the manager taps are the chips the donor sees.
///
/// Replaces the old flat `EquipmentModelOption` list: models are variants now.
class EquipmentOption extends Equatable {
  final int id;
  final String name;
  final String image;
  final String priceFrom;
  final String priceTo;
  final bool hasVariants;
  final List<OptionType> optionTypes;
  final List<EquipmentVariant> variants;

  const EquipmentOption({
    required this.id,
    this.name = '',
    this.image = '',
    this.priceFrom = '',
    this.priceTo = '',
    this.hasVariants = false,
    this.optionTypes = const [],
    this.variants = const [],
  });

  /// A product with no axes is picked as-is; the request then carries no
  /// `variant_id` (delivery §6.3).
  bool get needsVariant => hasVariants && variants.isNotEmpty;

  /// Cover for the picker row: the product's own image, else the first variant
  /// that has one.
  String get cover => image.isNotEmpty
      ? image
      : variants
            .firstWhere(
              (v) => v.image.isNotEmpty,
              orElse: () => const EquipmentVariant(id: 0),
            )
            .image;

  /// The variant matching a complete selection of option values, or null while
  /// the manager's selection is still partial.
  EquipmentVariant? variantFor(Set<int> selection) {
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
  /// and carries an image. Picking the colour therefore shows that colour's unit
  /// right away, instead of holding the catalogue cover until the last axis is
  /// answered. Empty when nothing matches.
  ///
  /// Returns the image and nothing else on purpose: a partial selection is not a
  /// pick, and carries neither a price nor an id to approve against.
  String representativeImage(Set<int> selection) {
    if (selection.isEmpty) return '';
    for (final variant in variants) {
      if (!variant.isAvailable || variant.image.isEmpty) continue;
      if (variant.optionValueIds.toSet().containsAll(selection)) {
        return variant.image;
      }
    }
    return '';
  }

  /// Which values of [axis] still lead to an available combination, given the
  /// picks on the other axes. Gaps are allowed, so unreachable values are
  /// offered disabled rather than hidden.
  Set<int> selectableValueIds(OptionType axis, Set<int> selection) {
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

  factory EquipmentOption.fromJson(Map<String, dynamic> j) {
    final effective = (j['effective_price'] ?? j['price'] ?? '').toString();
    return EquipmentOption(
      id: j['id'] as int? ?? 0,
      name: (j['name'] ?? '').toString(),
      image: (j['image'] ?? '').toString(),
      priceFrom: (j['price_from'] ?? effective).toString(),
      priceTo: (j['price_to'] ?? effective).toString(),
      hasVariants: j['has_variants'] as bool? ?? false,
      optionTypes: (j['option_types'] as List<dynamic>? ?? const [])
          .map((t) => OptionType.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList(growable: false),
      variants: (j['variants'] as List<dynamic>? ?? const [])
          .map(
            (v) =>
                EquipmentVariant.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [id, name, priceFrom, priceTo, variants];
}

/// What a picker resolves to: the product and, when it has axes, the picked
/// combination. Both travel to the server as ids.
class EquipmentPick extends Equatable {
  final EquipmentOption product;
  final EquipmentVariant? variant;

  const EquipmentPick({required this.product, this.variant});

  /// The goal this pick publishes — the variant's price, or the product's own
  /// when it has no axes.
  String get price => variant?.effectivePrice ?? product.priceFrom;

  /// "مبرّد مياه ستيل — حوضان — عادي" for confirmations and summaries.
  String get label => [
    product.name,
    if (variant != null && variant!.name.isNotEmpty) variant!.name,
  ].join(' — ');

  @override
  List<Object?> get props => [product, variant];
}

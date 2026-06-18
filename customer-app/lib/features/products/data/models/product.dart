import 'package:equatable/equatable.dart';
import 'package:sapbaq/features/products/data/models/product_media.dart';

/// A purchasable product. Prices are strings with 3 decimals (KWD), e.g.
/// "2.000" — kept as strings to preserve precision for display. The backend
/// resolves any active discount and returns `effective_price` already
/// computed; the app never re-derives it.
class Product extends Equatable {
  final int id;
  final String name;
  final String description;
  final String price; // original/list price
  final String effectivePrice; // price after discount — show this to the user
  final bool hasDiscount;
  final String? discountLabel; // e.g. "تخفيضات رمضان"
  final String? discountPercent; // populated only for PERCENT-type discounts
  final String? image; // cover image — used in lists and cards
  final List<ProductMedia> media; // extra images + video for the detail gallery
  final int? categoryId;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.effectivePrice,
    this.hasDiscount = false,
    this.discountLabel,
    this.discountPercent,
    this.image,
    this.media = const [],
    this.categoryId,
  });

  /// Unified gallery for the detail carousel: the cover [image] first (when
  /// present), then the [media] items in their server-provided order. The
  /// cover is not duplicated inside [media], so it appears exactly once.
  List<ProductMedia> get gallery => [
    if (image != null && image!.isNotEmpty)
      ProductMedia(id: -1, mediaType: 'IMAGE', file: image!, sortOrder: -1),
    ...media,
  ];

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
    return Product(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] ?? '0').toString(),
      effectivePrice: (json['effective_price'] ?? json['price'] ?? '0')
          .toString(),
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
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    effectivePrice,
    hasDiscount,
    media,
    categoryId,
  ];
}

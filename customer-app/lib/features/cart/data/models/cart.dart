import 'package:equatable/equatable.dart';
import 'package:sapbaq/features/gifts/data/models/gift.dart';

class CartItem extends Equatable {
  final int itemId;
  final int productId;
  final String productName;
  final int quantity;
  final String listPrice;
  final String unitPrice;
  final String lineTotal;
  final bool hasDiscount;

  /// The picked variant (PRODUCT_VARIANTS_BACKEND_DELIVERY §3.2) — null/'' for
  /// products without variants. Prices above already reflect the variant.
  /// Different variants of the same product are separate lines.
  final int? variantId;
  final String variantName;

  /// Dedication: the name engraved on the unit and whether the person is alive
  /// or deceased — always optional, and offered only when the product's flag is
  /// set. Empty for ordinary items. The same product with a different name is a
  /// separate line — never merged.
  final bool supportsDedication;
  final String dedicationName;
  final String dedicationStatus; // ALIVE | DECEASED | ''

  /// Line thumbnail (the picked variant's image when there is one, else the
  /// product cover), full URL. Null only when the product has no photo at all,
  /// so the row draws no thumb rather than an empty well.
  final String? image;

  const CartItem({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.listPrice,
    required this.unitPrice,
    required this.lineTotal,
    this.hasDiscount = false,
    this.variantId,
    this.variantName = '',
    this.supportsDedication = false,
    this.dedicationName = '',
    this.dedicationStatus = '',
    this.image,
  });

  /// The line's display name: the product plus the picked variant, e.g.
  /// «براد سبيل ستيل — بحنفيتين».
  String get displayName =>
      variantName.isEmpty ? productName : '$productName — $variantName';

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      itemId: json['item_id'] as int,
      productId: json['product_id'] as int,
      productName: (json['product_name'] ?? '').toString(),
      quantity: json['quantity'] as int? ?? 0,
      listPrice: (json['list_price'] ?? '0').toString(),
      unitPrice: (json['unit_price'] ?? '0').toString(),
      lineTotal: (json['line_total'] ?? '0').toString(),
      hasDiscount: json['has_discount'] as bool? ?? false,
      variantId: json['variant_id'] as int?,
      variantName: (json['variant_name'] ?? '').toString(),
      supportsDedication: json['supports_dedication'] as bool? ?? false,
      dedicationName: (json['dedication_name'] ?? '').toString(),
      dedicationStatus: (json['dedication_status'] ?? '')
          .toString()
          .toUpperCase(),
      image: switch ((json['image'] ?? '').toString()) {
        '' => null,
        final url => url,
      },
    );
  }

  @override
  List<Object?> get props => [
    itemId,
    productId,
    quantity,
    unitPrice,
    lineTotal,
    variantId,
    dedicationName,
    dedicationStatus,
  ];
}

/// A donation cart — a first-class entity bound to ONE mosque. The customer may
/// have several in parallel; each has its own items, coupon, gift and total,
/// but they are no longer paid one at a time: checkout combines every cart into
/// a single order across all their destinations, settled by one payment
/// (FLUTTER_COMBINED_CHECKOUT §2).
///
/// There is no anonymous "most needed" cart any more: every cart carries a real
/// [mosqueId] from the moment the first item is added (delivery §2).
class DonationCart extends Equatable {
  final int cartId;
  final int mosqueId;
  final String? mosqueName;
  final String? area;
  final String label;

  /// The mosque is on the admin's most-needed list — a badge beside its name.
  final bool isMostNeeded;

  /// The donor reached it through that list. Reporting only; it changes nothing
  /// about the cart.
  final bool viaMostNeeded;

  final List<CartItem> items;
  final int itemCount;
  final String subtotal;
  final String discountAmount;
  final String totalAmount;
  final String couponCode;
  final bool couponValid;
  final Gift? gift;

  const DonationCart({
    required this.cartId,
    required this.mosqueId,
    required this.label,
    required this.items,
    required this.itemCount,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.couponCode,
    required this.couponValid,
    this.isMostNeeded = false,
    this.viaMostNeeded = false,
    this.mosqueName,
    this.area,
    this.gift,
  });

  bool get hasCoupon => couponCode.isNotEmpty;

  factory DonationCart.fromJson(Map<String, dynamic> json) {
    return DonationCart(
      cartId: json['cart_id'] as int,
      mosqueId: json['mosque_id'] as int? ?? 0,
      isMostNeeded: json['is_most_needed'] as bool? ?? false,
      viaMostNeeded: json['via_most_needed'] as bool? ?? false,
      mosqueName: json['mosque_name'] as String?,
      area: json['area'] as String?,
      label: (json['label'] ?? '').toString(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      itemCount: json['item_count'] as int? ?? 0,
      subtotal: (json['subtotal'] ?? '0').toString(),
      discountAmount: (json['discount_amount'] ?? '0').toString(),
      totalAmount: (json['total_amount'] ?? '0').toString(),
      couponCode: (json['coupon_code'] ?? '').toString(),
      couponValid: json['coupon_valid'] as bool? ?? false,
      gift: json['gift'] is Map
          ? Gift.fromJson(Map<String, dynamic>.from(json['gift'] as Map))
          : null,
    );
  }

  /// Parse the `GET /carts/` list (or any mutation response, same shape).
  static List<DonationCart> listFrom(dynamic data) {
    final items = data is Map && data['results'] is List
        ? data['results'] as List
        : data as List? ?? const [];
    return items
        .map((e) => DonationCart.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  List<Object?> get props => [
    cartId,
    mosqueId,
    isMostNeeded,
    viaMostNeeded,
    items,
    subtotal,
    totalAmount,
    couponCode,
    gift,
  ];
}

import 'package:equatable/equatable.dart';

enum CartDestinationType { mosque, mostNeeded }

class CartItem extends Equatable {
  final int itemId;
  final int productId;
  final String productName;
  final int quantity;
  final String listPrice;
  final String unitPrice;
  final String lineTotal;
  final int stockAvailable;
  final bool hasDiscount;
  final bool stockWarning;

  const CartItem({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.listPrice,
    required this.unitPrice,
    required this.lineTotal,
    this.stockAvailable = 0,
    this.hasDiscount = false,
    this.stockWarning = false,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      itemId: json['item_id'] as int,
      productId: json['product_id'] as int,
      productName: (json['product_name'] ?? '').toString(),
      quantity: json['quantity'] as int? ?? 0,
      listPrice: (json['list_price'] ?? '0').toString(),
      unitPrice: (json['unit_price'] ?? '0').toString(),
      lineTotal: (json['line_total'] ?? '0').toString(),
      stockAvailable: json['stock_available'] as int? ?? 0,
      hasDiscount: json['has_discount'] as bool? ?? false,
      stockWarning: json['stock_warning'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [itemId, productId, quantity, unitPrice, lineTotal];
}

/// A destination group within the cart (one mosque, or the most-needed pool).
class CartGroup extends Equatable {
  final int groupId;
  final CartDestinationType type;
  final int? mosqueId;
  final String? mosqueName;
  final String? area;
  final String label;
  final List<CartItem> items;
  final String subtotal;
  final int itemCount;

  const CartGroup({
    required this.groupId,
    required this.type,
    required this.label,
    required this.items,
    required this.subtotal,
    this.mosqueId,
    this.mosqueName,
    this.area,
    this.itemCount = 0,
  });

  bool get isMostNeeded => type == CartDestinationType.mostNeeded;

  factory CartGroup.fromJson(Map<String, dynamic> json) {
    return CartGroup(
      groupId: json['group_id'] as int,
      type: (json['destination_type'] == 'MOST_NEEDED')
          ? CartDestinationType.mostNeeded
          : CartDestinationType.mosque,
      mosqueId: json['mosque_id'] as int?,
      mosqueName: json['mosque_name'] as String?,
      area: json['area'] as String?,
      label: (json['label'] ?? '').toString(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: (json['subtotal'] ?? '0').toString(),
      itemCount: json['item_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [groupId, type, mosqueId, items, subtotal];
}

class Cart extends Equatable {
  final int cartId;
  final List<CartGroup> groups;
  final String subtotal;
  final String discountAmount;
  final String totalAmount;
  final int destinationCount;
  final int itemCount;
  final String couponCode;
  final bool couponValid;

  const Cart({
    required this.cartId,
    required this.groups,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.destinationCount,
    required this.itemCount,
    required this.couponCode,
    required this.couponValid,
  });

  bool get isEmpty => groups.isEmpty;
  bool get hasCoupon => couponCode.isNotEmpty;

  static const Cart empty = Cart(
    cartId: 0,
    groups: [],
    subtotal: '0.000',
    discountAmount: '0.000',
    totalAmount: '0.000',
    destinationCount: 0,
    itemCount: 0,
    couponCode: '',
    couponValid: false,
  );

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      cartId: json['cart_id'] as int? ?? 0,
      groups: (json['groups'] as List<dynamic>? ?? const [])
          .map((e) => CartGroup.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: (json['subtotal'] ?? '0').toString(),
      discountAmount: (json['discount_amount'] ?? '0').toString(),
      totalAmount: (json['total_amount'] ?? '0').toString(),
      destinationCount: json['destination_count'] as int? ?? 0,
      itemCount: json['item_count'] as int? ?? 0,
      couponCode: (json['coupon_code'] ?? '').toString(),
      couponValid: json['coupon_valid'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [cartId, groups, totalAmount, couponCode, itemCount];
}

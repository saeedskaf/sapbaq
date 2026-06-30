import 'package:equatable/equatable.dart';
import 'package:sapbaq/features/auth/data/models/user.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';
import 'package:sapbaq/features/products/data/models/product.dart';

class OrderItem extends Equatable {
  final int id;
  final Product product;
  final int quantity;
  final String unitPrice;
  final String lineTotal;

  const OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unit_price'] ?? '0').toString(),
      lineTotal: (json['line_total'] ?? '0').toString(),
    );
  }

  @override
  List<Object?> get props => [id, quantity, lineTotal];
}

/// One delivery destination inside an order (a mosque, or the most-needed pool),
/// with its own independent [status].
class OrderDestination extends Equatable {
  final int id;
  final String destinationType; // MOSQUE | MOST_NEEDED
  final String label;
  final Mosque? mosque;
  final User? driver;
  final String status;
  final String subtotal;
  final List<OrderItem> items;

  // Per-destination lifecycle timestamps, each null until that step is reached.
  // Drive the per-destination delivery timeline (FLUTTER_TASKS T4).
  final String? assignedAt;
  final String? inDeliveryAt;
  final String? deliveredAt;
  final String? cancelledAt;

  const OrderDestination({
    required this.id,
    required this.destinationType,
    required this.label,
    required this.status,
    required this.subtotal,
    required this.items,
    this.mosque,
    this.driver,
    this.assignedAt,
    this.inDeliveryAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  bool get isMostNeeded => destinationType == 'MOST_NEEDED';

  factory OrderDestination.fromJson(Map<String, dynamic> json) {
    return OrderDestination(
      id: json['id'] as int,
      destinationType: (json['destination_type'] ?? 'MOSQUE').toString(),
      label: (json['label'] ?? '').toString(),
      mosque: json['mosque'] is Map
          ? Mosque.fromJson(Map<String, dynamic>.from(json['mosque'] as Map))
          : null,
      driver: json['driver'] is Map
          ? User.fromJson(Map<String, dynamic>.from(json['driver'] as Map))
          : null,
      status: (json['status'] ?? '').toString(),
      subtotal: (json['subtotal'] ?? '0').toString(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      assignedAt: json['assigned_at'] as String?,
      inDeliveryAt: json['in_delivery_at'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, driver, items];
}

class Order extends Equatable {
  final int id;
  final String reference;
  final String status;
  final List<OrderDestination> destinations;
  final String subtotal;
  final String discountAmount;
  final String totalAmount;
  final String? customerNotes;
  final String? createdAt;

  const Order({
    required this.id,
    required this.reference,
    required this.status,
    required this.destinations,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    this.customerNotes,
    this.createdAt,
  });

  bool get isPending => status == 'PENDING';
  int get destinationCount => destinations.length;
  String get shortReference =>
      reference.length >= 8 ? reference.substring(0, 8) : reference;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      reference: (json['reference'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      destinations: (json['destinations'] as List<dynamic>? ?? const [])
          .map((e) =>
              OrderDestination.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: (json['subtotal'] ?? '0').toString(),
      discountAmount: (json['discount_amount'] ?? '0').toString(),
      totalAmount: (json['total_amount'] ?? '0').toString(),
      customerNotes: json['customer_notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, totalAmount, destinations];
}

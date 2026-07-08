import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/features/shared/data/models/mosque.dart';
import 'package:sapbaq_admin/features/shared/data/models/order_customer.dart';
import 'package:sapbaq_admin/features/shared/data/models/order_item.dart';

/// A delivery destination assigned to the driver (workshop), from
/// `GET /orders/driver/destinations/`. The driver works on destinations, not
/// whole orders — one order may span several workshops.
class DriverDestination extends Equatable {
  final int id;
  final int orderId;
  final String orderReference;
  final String orderCode; // human-readable "ORD-00001" (FLUTTER_TASKS item 17)
  final String destinationType; // MOSQUE | MOST_NEEDED
  final String label;
  final String status; // ASSIGNED | IN_DELIVERY | DELIVERED | ...
  final Mosque? mosque;
  final OrderCustomer? customer;
  final String? customerNotes;
  final String subtotal;
  final List<OrderItem> items;
  final String? assignedAt;
  final String? acceptedAt;
  final String? inDeliveryAt;
  final String? deliveredAt;

  const DriverDestination({
    required this.id,
    required this.orderId,
    required this.orderReference,
    required this.destinationType,
    required this.label,
    required this.status,
    required this.subtotal,
    required this.items,
    this.orderCode = '',
    this.mosque,
    this.customer,
    this.customerNotes,
    this.assignedAt,
    this.acceptedAt,
    this.inDeliveryAt,
    this.deliveredAt,
  });

  bool get isAccepted => acceptedAt != null;
  bool get isAssigned => status == 'ASSIGNED';
  bool get isInDelivery => status == 'IN_DELIVERY';
  bool get isDelivered => status == 'DELIVERED';

  /// A freshly assigned destination the driver hasn't accepted yet.
  bool get isNew => isAssigned && !isAccepted;

  /// Accepted but not yet started — ready for "start delivery".
  bool get canStartDelivery => isAssigned && isAccepted;

  String get shortReference => orderReference.length >= 8
      ? orderReference.substring(0, 8)
      : orderReference;

  /// What to show the user as the order number: the readable [orderCode],
  /// falling back to the reference prefix if the backend didn't send one.
  String get displayCode => orderCode.isNotEmpty ? orderCode : '#$shortReference';

  factory DriverDestination.fromJson(Map<String, dynamic> json) {
    return DriverDestination(
      id: json['id'] as int,
      orderId: json['order_id'] as int? ?? 0,
      orderReference: (json['order_reference'] ?? '').toString(),
      orderCode: (json['order_code'] ?? '').toString(),
      destinationType: (json['destination_type'] ?? 'MOSQUE').toString(),
      label: (json['label'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mosque: json['mosque'] is Map
          ? Mosque.fromJson(Map<String, dynamic>.from(json['mosque'] as Map))
          : null,
      customer: json['customer'] is Map
          ? OrderCustomer.fromJson(
              Map<String, dynamic>.from(json['customer'] as Map),
            )
          : null,
      customerNotes: json['customer_notes'] as String?,
      subtotal: (json['subtotal'] ?? '0').toString(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      assignedAt: json['assigned_at'] as String?,
      acceptedAt: json['accepted_at'] as String?,
      inDeliveryAt: json['in_delivery_at'] as String?,
      deliveredAt: json['delivered_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, acceptedAt, inDeliveryAt, deliveredAt];
}

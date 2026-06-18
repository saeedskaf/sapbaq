import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/features/shared/data/models/delivery_proof.dart';
import 'package:sapbaq_admin/features/shared/data/models/mosque.dart';
import 'package:sapbaq_admin/features/shared/data/models/order_customer.dart';
import 'package:sapbaq_admin/features/shared/data/models/order_item.dart';
import 'package:sapbaq_admin/features/shared/data/models/payment.dart';

/// Row in the admin orders list (`GET /admin/orders/`).
class AdminOrderSummary extends Equatable {
  final int id;
  final String reference;
  final String status;
  final OrderCustomer? customer;
  final String totalAmount;
  final int destinationCount;
  final bool awaitingAssignment;
  final String? createdAt;

  const AdminOrderSummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.totalAmount,
    required this.destinationCount,
    required this.awaitingAssignment,
    this.customer,
    this.createdAt,
  });

  String get shortReference =>
      reference.length >= 8 ? reference.substring(0, 8) : reference;

  factory AdminOrderSummary.fromJson(Map<String, dynamic> json) {
    return AdminOrderSummary(
      id: json['id'] as int,
      reference: (json['reference'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      customer: json['customer'] is Map
          ? OrderCustomer.fromJson(
              Map<String, dynamic>.from(json['customer'] as Map),
            )
          : null,
      totalAmount: (json['total_amount'] ?? '0').toString(),
      destinationCount: json['destination_count'] as int? ?? 0,
      awaitingAssignment: json['awaiting_assignment'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, awaitingAssignment, totalAmount];
}

/// One delivery destination inside an admin order. Carries the assigned
/// workshop ([driver]) once assigned, and the [mosque] (null for an
/// unassigned MOST_NEEDED destination).
class AdminDestination extends Equatable {
  final int id;
  final String destinationType; // MOSQUE | MOST_NEEDED
  final String label;
  final String status;
  final Mosque? mosque;
  final OrderCustomer? driver; // the assigned workshop
  final String subtotal;
  final List<OrderItem> items;

  const AdminDestination({
    required this.id,
    required this.destinationType,
    required this.label,
    required this.status,
    required this.subtotal,
    required this.items,
    this.mosque,
    this.driver,
  });

  bool get isMostNeeded => destinationType == 'MOST_NEEDED';
  bool get isPending => status == 'PENDING';

  /// A MOST_NEEDED destination still needs a mosque chosen at assignment time.
  bool get needsMosque => isMostNeeded && mosque == null;

  factory AdminDestination.fromJson(Map<String, dynamic> json) {
    return AdminDestination(
      id: json['id'] as int,
      destinationType: (json['destination_type'] ?? 'MOSQUE').toString(),
      label: (json['label'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mosque: json['mosque'] is Map
          ? Mosque.fromJson(Map<String, dynamic>.from(json['mosque'] as Map))
          : null,
      driver: json['driver'] is Map
          ? OrderCustomer.fromJson(
              Map<String, dynamic>.from(json['driver'] as Map),
            )
          : null,
      subtotal: (json['subtotal'] ?? '0').toString(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, status, driver, mosque, items];
}

/// Full admin order (`GET /admin/orders/{id}/`).
class AdminOrderDetail extends Equatable {
  final int id;
  final String reference;
  final String status;
  final OrderCustomer? customer;
  final String subtotal;
  final String discountAmount;
  final String totalAmount;
  final String couponCode;
  final String? customerNotes;
  final String? cancellationReason;
  final Payment? payment;
  final bool hasGift;
  final List<DeliveryProof> proofs;
  final List<AdminDestination> destinations;
  final String? createdAt;

  const AdminOrderDetail({
    required this.id,
    required this.reference,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.destinations,
    this.customer,
    this.couponCode = '',
    this.customerNotes,
    this.cancellationReason,
    this.payment,
    this.hasGift = false,
    this.proofs = const [],
    this.createdAt,
  });

  String get shortReference =>
      reference.length >= 8 ? reference.substring(0, 8) : reference;

  /// Destinations still awaiting assignment (status PENDING).
  List<AdminDestination> get pendingDestinations =>
      destinations.where((d) => d.isPending).toList();

  bool get awaitingAssignment => pendingDestinations.isNotEmpty;

  bool get isCancellable => status != 'CANCELLED' && status != 'DELIVERED';

  factory AdminOrderDetail.fromJson(Map<String, dynamic> json) {
    return AdminOrderDetail(
      id: json['id'] as int,
      reference: (json['reference'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      customer: json['customer'] is Map
          ? OrderCustomer.fromJson(
              Map<String, dynamic>.from(json['customer'] as Map),
            )
          : null,
      subtotal: (json['subtotal'] ?? '0').toString(),
      discountAmount: (json['discount_amount'] ?? '0').toString(),
      totalAmount: (json['total_amount'] ?? '0').toString(),
      couponCode: (json['coupon_code_snapshot'] ?? '').toString(),
      customerNotes: json['customer_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      payment: json['payment'] is Map
          ? Payment.fromJson(Map<String, dynamic>.from(json['payment'] as Map))
          : null,
      hasGift: json['gift'] != null,
      proofs: (json['proofs'] as List<dynamic>? ?? const [])
          .map((e) => DeliveryProof.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      destinations: (json['destinations'] as List<dynamic>? ?? const [])
          .map((e) =>
              AdminDestination.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, totalAmount, destinations];
}

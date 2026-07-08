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
  final String code; // human-readable "ORD-00001" (FLUTTER_TASKS item 17)
  final String status;
  final OrderCustomer? customer;
  final String totalAmount;
  final int destinationCount;
  final bool awaitingAssignment;
  final String? createdAt;
  final String? statusUpdatedAt; // last status change (item 8)

  const AdminOrderSummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.totalAmount,
    required this.destinationCount,
    required this.awaitingAssignment,
    this.code = '',
    this.customer,
    this.createdAt,
    this.statusUpdatedAt,
  });

  String get shortReference =>
      reference.length >= 8 ? reference.substring(0, 8) : reference;

  /// What to show the user as the order number: the readable [code], falling
  /// back to the reference prefix if the backend didn't send one.
  String get displayCode => code.isNotEmpty ? code : '#$shortReference';

  factory AdminOrderSummary.fromJson(Map<String, dynamic> json) {
    return AdminOrderSummary(
      id: json['id'] as int,
      reference: (json['reference'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
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
      statusUpdatedAt: json['status_updated_at'] as String?,
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
  final OrderCustomer? teamLeader; // the team leader the order was assigned to
  final OrderCustomer? driver; // the assigned workshop (handler)
  final String subtotal;
  final List<OrderItem> items;

  // Per-destination lifecycle timestamps (FLUTTER_TASKS T4), each null until
  // the destination reaches that step.
  final String? assignedAt;
  final String? inDeliveryAt;
  final String? deliveredAt;
  final String? cancelledAt;

  const AdminDestination({
    required this.id,
    required this.destinationType,
    required this.label,
    required this.status,
    required this.subtotal,
    required this.items,
    this.mosque,
    this.teamLeader,
    this.driver,
    this.assignedAt,
    this.inDeliveryAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  bool get isMostNeeded => destinationType == 'MOST_NEEDED';
  bool get isPending => status == 'PENDING';

  /// Assigned to a team leader, awaiting distribution to a handler (T3).
  bool get isAssignedToTeam => status == 'ASSIGNED_TO_TEAM';

  /// A MOST_NEEDED destination still needs a mosque chosen at assignment time.
  bool get needsMosque => isMostNeeded && mosque == null;

  /// Whether this destination can be moved to another workshop (§5): it has a
  /// current workshop and isn't already in delivery or finished. A destination
  /// still with the team leader (no handler yet) is distributed, not reassigned.
  bool get isReassignable =>
      driver != null &&
      status != 'IN_DELIVERY' &&
      status != 'DELIVERED' &&
      status != 'CANCELLED';

  factory AdminDestination.fromJson(Map<String, dynamic> json) {
    return AdminDestination(
      id: json['id'] as int,
      destinationType: (json['destination_type'] ?? 'MOSQUE').toString(),
      label: (json['label'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mosque: json['mosque'] is Map
          ? Mosque.fromJson(Map<String, dynamic>.from(json['mosque'] as Map))
          : null,
      teamLeader: json['team_leader'] is Map
          ? OrderCustomer.fromJson(
              Map<String, dynamic>.from(json['team_leader'] as Map),
            )
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
      assignedAt: json['assigned_at'] as String?,
      inDeliveryAt: json['in_delivery_at'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, teamLeader, driver, mosque, items];
}

/// Full admin order (`GET /admin/orders/{id}/`).
class AdminOrderDetail extends Equatable {
  final int id;
  final String reference;
  final String code; // human-readable "ORD-00001" (FLUTTER_TASKS item 17)
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
  final List<OrderTimelineEvent> timeline;
  final String? createdAt;

  const AdminOrderDetail({
    required this.id,
    required this.reference,
    required this.status,
    this.code = '',
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.destinations,
    this.timeline = const [],
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

  /// What to show the user as the order number: the readable [code], falling
  /// back to the reference prefix if the backend didn't send one.
  String get displayCode => code.isNotEmpty ? code : '#$shortReference';

  /// Destinations still awaiting assignment (status PENDING).
  List<AdminDestination> get pendingDestinations =>
      destinations.where((d) => d.isPending).toList();

  bool get awaitingAssignment => pendingDestinations.isNotEmpty;

  bool get isCancellable => status != 'CANCELLED' && status != 'DELIVERED';

  factory AdminOrderDetail.fromJson(Map<String, dynamic> json) {
    return AdminOrderDetail(
      id: json['id'] as int,
      reference: (json['reference'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
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
      timeline: (json['timeline'] as List<dynamic>? ?? const [])
          .map((e) =>
              OrderTimelineEvent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, totalAmount, destinations, timeline];
}

/// One entry in an order's timeline (`GET /admin/orders/{id}/` → `timeline`,
/// STAFF_APP_API_HANDOFF §4). The backend returns them ordered oldest→newest;
/// [label] is server-localized — display it as-is.
class OrderTimelineEvent extends Equatable {
  final String at; // ISO 8601
  final String event; // e.g. "order.created", "destination.assigned"
  final String label;
  final int? destinationId;

  const OrderTimelineEvent({
    required this.at,
    required this.event,
    required this.label,
    this.destinationId,
  });

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEvent(
      at: (json['at'] ?? '').toString(),
      event: (json['event'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      destinationId: json['destination_id'] as int?,
    );
  }

  @override
  List<Object?> get props => [at, event, label, destinationId];
}

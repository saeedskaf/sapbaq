import 'package:equatable/equatable.dart';

/// The daily summary from `GET /admin/me/dashboard/` (STAFF_APP_API_HANDOFF §6).
/// Scope (personal / regional / global) follows the caller's role on the server.
class DashboardSummary extends Equatable {
  final DashboardOrders orders;
  final double completionRate; // 0..1
  final DashboardSla sla;

  const DashboardSummary({
    required this.orders,
    this.completionRate = 0,
    this.sla = const DashboardSla(),
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      orders: DashboardOrders.fromJson(
        json['orders'] is Map
            ? Map<String, dynamic>.from(json['orders'] as Map)
            : const {},
      ),
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      sla: DashboardSla.fromJson(
        json['sla'] is Map
            ? Map<String, dynamic>.from(json['sla'] as Map)
            : const {},
      ),
    );
  }

  @override
  List<Object?> get props => [orders, completionRate, sla];
}

/// Order tallies for the dashboard. `new`=PENDING, `assigned`=CONFIRMED,
/// `completed`=DELIVERED.
class DashboardOrders extends Equatable {
  final int newOrders;
  final int assigned;
  final int completed;
  final int cancelled;
  final int all;
  final int awaitingAssignment;

  const DashboardOrders({
    this.newOrders = 0,
    this.assigned = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.all = 0,
    this.awaitingAssignment = 0,
  });

  factory DashboardOrders.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return DashboardOrders(
      newOrders: read('new'),
      assigned: read('assigned'),
      completed: read('completed'),
      cancelled: read('cancelled'),
      all: read('all'),
      awaitingAssignment: read('awaiting_assignment'),
    );
  }

  @override
  List<Object?> get props => [
    newOrders,
    assigned,
    completed,
    cancelled,
    all,
    awaitingAssignment,
  ];
}

/// SLA averages. Any field may be null when there are no completed orders yet.
class DashboardSla extends Equatable {
  final double? avgMinutesToConfirm;
  final double? avgMinutesToDeliver;
  final int deliveredSample;

  const DashboardSla({
    this.avgMinutesToConfirm,
    this.avgMinutesToDeliver,
    this.deliveredSample = 0,
  });

  factory DashboardSla.fromJson(Map<String, dynamic> json) {
    return DashboardSla(
      avgMinutesToConfirm: (json['avg_minutes_to_confirm'] as num?)?.toDouble(),
      avgMinutesToDeliver: (json['avg_minutes_to_deliver'] as num?)?.toDouble(),
      deliveredSample: (json['delivered_sample'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    avgMinutesToConfirm,
    avgMinutesToDeliver,
    deliveredSample,
  ];
}

import 'package:equatable/equatable.dart';

/// Per-tab order counts from `GET /admin/orders/counts/` (STAFF_APP_API_HANDOFF
/// §3). Honors the same filters as the list except `status`.
class AdminOrderCounts extends Equatable {
  final int pending;
  final int confirmed;
  final int delivered;
  final int cancelled;
  final int awaitingAssignment;
  final int all;

  const AdminOrderCounts({
    this.pending = 0,
    this.confirmed = 0,
    this.delivered = 0,
    this.cancelled = 0,
    this.awaitingAssignment = 0,
    this.all = 0,
  });

  factory AdminOrderCounts.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return AdminOrderCounts(
      pending: read('PENDING'),
      confirmed: read('CONFIRMED'),
      delivered: read('DELIVERED'),
      cancelled: read('CANCELLED'),
      awaitingAssignment: read('awaiting_assignment'),
      all: read('all'),
    );
  }

  @override
  List<Object?> get props => [
    pending,
    confirmed,
    delivered,
    cancelled,
    awaitingAssignment,
    all,
  ];
}

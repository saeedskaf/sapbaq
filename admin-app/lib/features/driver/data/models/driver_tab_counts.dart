import 'package:equatable/equatable.dart';

/// Per-tab destination counts for the driver deliveries tab badges. There is no
/// dedicated counts endpoint, so these are derived from the destinations list:
/// New + Accepted both come from ASSIGNED (split by `accepted_at`), In-delivery
/// from IN_DELIVERY, and Completed from DELIVERED.
class DriverTabCounts extends Equatable {
  final int newJobs;
  final int accepted;
  final int inDelivery;
  final int completed;

  const DriverTabCounts({
    this.newJobs = 0,
    this.accepted = 0,
    this.inDelivery = 0,
    this.completed = 0,
  });

  @override
  List<Object?> get props => [newJobs, accepted, inDelivery, completed];
}

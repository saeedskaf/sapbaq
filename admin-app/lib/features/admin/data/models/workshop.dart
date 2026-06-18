import 'package:equatable/equatable.dart';

/// A workshop (DRIVER account) from `GET /admin/workshops/`. [activeLoad] is the
/// number of current deliveries (ASSIGNED + IN_DELIVERY) — used to balance load
/// when assigning.
class Workshop extends Equatable {
  final int id;
  final String phone;
  final String fullName;
  final int activeLoad;

  const Workshop({
    required this.id,
    required this.phone,
    required this.fullName,
    this.activeLoad = 0,
  });

  factory Workshop.fromJson(Map<String, dynamic> json) {
    return Workshop(
      id: json['id'] as int,
      phone: (json['phone'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      activeLoad: json['active_load'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, phone, fullName, activeLoad];
}

/// One destination → workshop (+ optional mosque) assignment, sent in the
/// single `POST /admin/orders/{id}/assign/` call.
class Assignment extends Equatable {
  final int destinationId;
  final int driverId;
  final int? mosqueId; // required for MOST_NEEDED destinations

  const Assignment({
    required this.destinationId,
    required this.driverId,
    this.mosqueId,
  });

  Map<String, dynamic> toJson() => {
    'destination_id': destinationId,
    'driver_id': driverId,
    if (mosqueId != null) 'mosque_id': mosqueId,
  };

  @override
  List<Object?> get props => [destinationId, driverId, mosqueId];
}

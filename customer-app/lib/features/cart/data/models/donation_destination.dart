import 'package:equatable/equatable.dart';

/// Where a donation goes — **always a specific mosque**.
///
/// "الأكثر حاجة" is no longer an anonymous pool: it is a curated list the admin
/// maintains, and the donor picks one mosque out of it. [viaMostNeeded] only
/// records that they arrived that way (for the badge and for reporting); the
/// destination itself is a mosque either way (delivery §4).
class DonationDestination extends Equatable {
  final int mosqueId;
  final String label;

  /// The mosque carries the admin's most-needed tag.
  final bool isMostNeeded;

  /// The donor reached this mosque through the most-needed list.
  final bool viaMostNeeded;

  const DonationDestination({
    required this.mosqueId,
    required this.label,
    this.isMostNeeded = false,
    this.viaMostNeeded = false,
  });

  /// Extra params for `POST /carts/items/` — a mosque is mandatory now, and
  /// `most_needed: true` is no longer accepted in its place.
  Map<String, dynamic> toItemParams() => {
    'mosque_id': mosqueId,
    if (viaMostNeeded) 'via_most_needed': true,
  };

  @override
  List<Object?> get props => [mosqueId, label, isMostNeeded, viaMostNeeded];
}

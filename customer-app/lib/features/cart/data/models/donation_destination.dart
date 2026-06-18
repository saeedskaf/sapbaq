import 'package:equatable/equatable.dart';

/// Where a donation goes: a specific mosque, or the "most needed" pool.
/// Used as the destination context when adding products to the cart.
class DonationDestination extends Equatable {
  final int? mosqueId; // null = most needed
  final String label;

  const DonationDestination.mosque({required int this.mosqueId, required this.label});

  const DonationDestination.mostNeeded({required this.label}) : mosqueId = null;

  bool get isMostNeeded => mosqueId == null;

  /// Extra params for `POST /cart/items/`.
  Map<String, dynamic> toItemParams() =>
      isMostNeeded ? {'most_needed': true} : {'mosque_id': mosqueId};

  @override
  List<Object?> get props => [mosqueId, label];
}

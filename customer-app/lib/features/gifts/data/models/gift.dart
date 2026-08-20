import 'package:equatable/equatable.dart';

/// An "إهداء" attached to the cart/order: water gifted in someone's name,
/// with a WhatsApp notice to [notifyPhone].
///
/// The card artwork is chosen server-side from the one design the admin marks
/// as approved — the donor never picks it, so there is no template here
/// (GIFT_SIMPLIFIED_2026-08-04 §2/§5).
class Gift extends Equatable {
  /// The cart payload sends only the three fields below, so treat the id as
  /// optional — a strict cast here would break parsing of the whole cart list.
  final int? id;
  final String dedicatedToName;
  final String senderName;
  final String notifyPhone;

  const Gift({
    this.id,
    required this.dedicatedToName,
    required this.senderName,
    required this.notifyPhone,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: (json['id'] as num?)?.toInt(),
      dedicatedToName: (json['dedicated_to_name'] ?? '').toString(),
      senderName: (json['sender_name'] ?? '').toString(),
      notifyPhone: (json['notify_phone'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, dedicatedToName, senderName, notifyPhone];
}

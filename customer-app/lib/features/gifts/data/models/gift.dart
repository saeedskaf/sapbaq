import 'package:equatable/equatable.dart';

/// A gift-card template (the artwork the sender's/recipient's names get
/// printed on). [categoryId] links it to a [GiftCategory].
class GiftTemplate extends Equatable {
  final int id;
  final String label;
  final String? image;
  final int? categoryId;

  const GiftTemplate({
    required this.id,
    required this.label,
    this.image,
    this.categoryId,
  });

  factory GiftTemplate.fromJson(Map<String, dynamic> json) {
    return GiftTemplate(
      id: json['id'] as int,
      label: (json['label'] ?? '').toString(),
      image: json['image'] as String?,
      categoryId: json['category_id'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, label, image, categoryId];
}

/// An "إهداء" attached to the cart/order: water gifted in someone's name,
/// with a WhatsApp notice to [notifyPhone].
class Gift extends Equatable {
  final int id;
  final String dedicatedToName;
  final String senderName;
  final String relationType;
  final String notifyPhone;
  final GiftTemplate? template;

  const Gift({
    required this.id,
    required this.dedicatedToName,
    required this.senderName,
    required this.relationType,
    required this.notifyPhone,
    this.template,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'] as int,
      dedicatedToName: (json['dedicated_to_name'] ?? '').toString(),
      senderName: (json['sender_name'] ?? '').toString(),
      relationType: (json['relation_type'] ?? 'GENERAL').toString(),
      notifyPhone: (json['notify_phone'] ?? '').toString(),
      template: json['template'] is Map
          ? GiftTemplate.fromJson(Map<String, dynamic>.from(json['template'] as Map))
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    dedicatedToName,
    senderName,
    relationType,
    notifyPhone,
  ];
}

import 'package:equatable/equatable.dart';

/// A gift (إهداء) category the customer picks first (e.g. الزوجة، الوالد). The
/// server infers `relation_type` from it, so the form no longer asks for one.
/// [icon] is an absolute URL and may be null (show a placeholder).
class GiftCategory extends Equatable {
  final int id;
  final String name;
  final String? icon;
  final String relationType;

  const GiftCategory({
    required this.id,
    required this.name,
    this.icon,
    this.relationType = 'GENERAL',
  });

  factory GiftCategory.fromJson(Map<String, dynamic> json) {
    return GiftCategory(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      icon: json['icon'] as String?,
      relationType: (json['relation_type'] ?? 'GENERAL').toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, icon, relationType];
}

import 'package:equatable/equatable.dart';

/// A grouping of products in the catalog (water bottles, water coolers, …).
/// The customer picks a category as a top-level tab in the products screen.
class ProductCategory extends Equatable {
  final int id;
  final String name;
  final String? icon;

  const ProductCategory({required this.id, required this.name, this.icon});

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: json['id'] as int,
        name: (json['name'] ?? '').toString(),
        icon: json['icon'] as String?,
      );

  @override
  List<Object?> get props => [id, name, icon];
}

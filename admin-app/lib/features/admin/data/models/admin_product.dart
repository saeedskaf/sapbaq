import 'package:equatable/equatable.dart';

/// A product as seen by staff (`GET /admin/products/`, STAFF_APP_API_HANDOFF
/// §11). [isAvailable] is the temporary suspend/hide flag staff can toggle;
/// [isActive] is the permanent catalog flag (web-only, shown read-only here).
class AdminProduct extends Equatable {
  final int id;
  final String name;
  final String nameEn;
  final int? categoryId;
  final String categoryName;
  final String price;
  final bool isActive;
  final bool isAvailable;

  /// Product cover, absolute URL, null when the product has none. Staff suspend
  /// and hide products from this list, and a name alone is a thin thing to act
  /// on when a catalogue holds several near-identical units.
  final String? image;

  /// How many combinations this product sells. Suspending the product suspends
  /// every one of them, so the count is the blast radius of the toggle beside
  /// it. 0 for a product without variants.
  final int variantCount;

  const AdminProduct({
    required this.id,
    required this.name,
    this.nameEn = '',
    this.categoryId,
    this.categoryName = '',
    this.price = '0',
    this.isActive = true,
    this.isAvailable = true,
    this.image,
    this.variantCount = 0,
  });

  AdminProduct copyWith({bool? isAvailable}) => AdminProduct(
    id: id,
    name: name,
    nameEn: nameEn,
    categoryId: categoryId,
    categoryName: categoryName,
    price: price,
    isActive: isActive,
    isAvailable: isAvailable ?? this.isAvailable,
    image: image,
    variantCount: variantCount,
  );

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    return AdminProduct(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '').toString(),
      nameEn: (json['name_en'] ?? '').toString(),
      categoryId: json['category_id'] as int?,
      categoryName: (json['category_name'] ?? '').toString(),
      price: (json['price'] ?? '0').toString(),
      isActive: json['is_active'] as bool? ?? true,
      isAvailable: json['is_available'] as bool? ?? true,
      image: switch ((json['image'] ?? '').toString()) {
        '' => null,
        final url => url,
      },
      variantCount: json['variant_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, price, isActive, isAvailable];
}

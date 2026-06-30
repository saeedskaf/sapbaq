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

  const AdminProduct({
    required this.id,
    required this.name,
    this.nameEn = '',
    this.categoryId,
    this.categoryName = '',
    this.price = '0',
    this.isActive = true,
    this.isAvailable = true,
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
    );
  }

  @override
  List<Object?> get props => [id, name, price, isActive, isAvailable];
}

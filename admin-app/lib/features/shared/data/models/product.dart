import 'package:equatable/equatable.dart';

/// A product as embedded in order items. Prices are strings (KWD) to preserve
/// precision for display.
class Product extends Equatable {
  final int id;
  final String name;
  final String price;
  final String? image;

  const Product({
    required this.id,
    required this.name,
    this.price = '0',
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '').toString(),
      price: (json['price'] ?? '0').toString(),
      image: json['image'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, price];
}

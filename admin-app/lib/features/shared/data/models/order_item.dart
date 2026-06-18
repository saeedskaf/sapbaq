import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/features/shared/data/models/product.dart';

/// A line item inside an order destination: a product + quantity + totals.
class OrderItem extends Equatable {
  final int id;
  final Product product;
  final int quantity;
  final String unitPrice;
  final String lineTotal;

  const OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int? ?? 0,
      product: Product.fromJson(
        Map<String, dynamic>.from(json['product'] as Map),
      ),
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unit_price'] ?? '0').toString(),
      lineTotal: (json['line_total'] ?? '0').toString(),
    );
  }

  @override
  List<Object?> get props => [id, quantity, lineTotal];
}

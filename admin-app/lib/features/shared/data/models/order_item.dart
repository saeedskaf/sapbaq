import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/features/shared/data/models/product.dart';

/// A line item inside an order destination: a product + quantity + totals.
class OrderItem extends Equatable {
  final int id;
  final Product product;
  final int quantity;
  final String unitPrice;
  final String lineTotal;

  /// Dedication snapshot (e.g. sabeel coolers): the name to engrave and whether
  /// the person is alive or deceased. Empty for ordinary items. The fulfilment
  /// team engraves the cooler with this.
  final String dedicationName;
  final String dedicationStatus; // ALIVE | DECEASED | ''

  /// The picked variant's name, snapshotted at order time (PRODUCT_VARIANTS_
  /// BACKEND_DELIVERY §4) — the field team must deliver this exact option.
  /// '' for products without variants.
  final String variantName;

  const OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.dedicationName = '',
    this.dedicationStatus = '',
    this.variantName = '',
  });

  /// Product + variant for display, e.g. «براد سبيل — بحنفيتين».
  String get displayName =>
      variantName.isEmpty ? product.name : '${product.name} — $variantName';

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int? ?? 0,
      product: Product.fromJson(
        Map<String, dynamic>.from(json['product'] as Map),
      ),
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unit_price'] ?? '0').toString(),
      lineTotal: (json['line_total'] ?? '0').toString(),
      dedicationName: (json['dedication_name'] ?? '').toString(),
      dedicationStatus: (json['dedication_status'] ?? '')
          .toString()
          .toUpperCase(),
      variantName: (json['variant_name'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    quantity,
    lineTotal,
    dedicationName,
    variantName,
  ];
}

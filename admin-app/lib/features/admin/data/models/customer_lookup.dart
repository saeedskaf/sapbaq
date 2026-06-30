import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/features/admin/data/models/admin_order.dart';
import 'package:sapbaq_admin/features/shared/data/models/order_customer.dart';

/// One matched customer + their full order history, from
/// `GET /admin/customers/lookup/` (STAFF_APP_API_HANDOFF §7). Every lookup is
/// recorded in the server's audit log.
class CustomerLookupResult extends Equatable {
  final OrderCustomer customer;
  final List<AdminOrderSummary> orders;

  const CustomerLookupResult({required this.customer, this.orders = const []});

  factory CustomerLookupResult.fromJson(Map<String, dynamic> json) {
    return CustomerLookupResult(
      customer: OrderCustomer.fromJson(
        json['customer'] is Map
            ? Map<String, dynamic>.from(json['customer'] as Map)
            : const {},
      ),
      orders: (json['orders'] as List<dynamic>? ?? const [])
          .map((e) =>
              AdminOrderSummary.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [customer, orders];
}

import 'package:equatable/equatable.dart';

/// A customer as embedded in admin orders / driver destinations:
/// `{id, phone, full_name}`.
class OrderCustomer extends Equatable {
  final int id;
  final String phone;
  final String fullName;

  const OrderCustomer({
    required this.id,
    required this.phone,
    required this.fullName,
  });

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    return OrderCustomer(
      id: json['id'] as int? ?? 0,
      phone: (json['phone'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, phone, fullName];
}

import 'package:equatable/equatable.dart';

/// The payment attached to an order: `{id, status, amount, provider, paid_at}`.
class Payment extends Equatable {
  final int id;
  final String status; // e.g. PAID
  final String amount;
  final String provider;
  final String? paidAt;

  const Payment({
    required this.id,
    required this.status,
    required this.amount,
    required this.provider,
    this.paidAt,
  });

  bool get isPaid => status == 'PAID';

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int? ?? 0,
      status: (json['status'] ?? '').toString(),
      amount: (json['amount'] ?? '0').toString(),
      provider: (json['provider'] ?? '').toString(),
      paidAt: json['paid_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, amount, provider, paidAt];
}

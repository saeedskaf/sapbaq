import 'package:equatable/equatable.dart';
import 'package:sapbaq/core/utils/money.dart';

/// One payment attempt, as returned by `POST /payments/initiate/`,
/// `POST /equipment-requests/{id}/pay/` and `POST /payments/confirm/`
/// (FLUTTER_PAYMENTS_MYFATOORAH §1).
///
/// Exactly one of [orderId] / [contributionId] / [equipmentOrderId] is set —
/// which one depends on what was paid for.
class Payment extends Equatable {
  final int id;

  /// PENDING → PAID | FAILED, and PAID → REFUNDED via support (§6).
  final String status;
  final String amount;

  /// `mock` until MyFatoorah is switched on, then `myfatoorah`.
  final String provider;
  final String providerReference;

  /// The hosted payment page to open. Empty in mock mode — that's the signal
  /// to skip the browser and confirm straight away (§3).
  final String redirectUrl;

  final int? orderId;
  final int? contributionId;
  final int? equipmentOrderId;

  /// The gateway's invoice number. Worth carrying purely so a support ticket
  /// can be matched to a transaction without a database dig.
  final int? invoiceId;

  /// Why the gateway refused, in English, for support and logs —
  /// `InvoiceStatus=Failed` and the like. **Never shown to a customer.**
  final String? failureReason;

  /// The same refusal written for the customer, in Arabic, by the server.
  ///
  /// Two fields rather than one because they have two jobs: this one goes on
  /// screen, [failureReason] goes in a ticket. A single field would inevitably
  /// end up doing the wrong one of the two.
  final String? failureMessageAr;

  /// The gateway's code for the **last refused attempt on an invoice that is
  /// still payable** — `AUTHENTICATION_UNSUCCESSFUL`, `TIMED_OUT`, and whatever
  /// MyFatoorah adds next without telling anyone. For logs and tickets; never
  /// shown to a customer.
  ///
  /// Present on `initiate` and `confirm` only, never on `execute`.
  final String? lastAttemptError;

  /// The same refusal written for the customer, in Arabic, by the server.
  /// Guaranteed to carry a displayable sentence whatever [lastAttemptError]
  /// turns out to be, which is what makes an unknown code safe to handle.
  final String? lastAttemptMessageAr;

  final DateTime? paidAt;

  const Payment({
    required this.id,
    required this.status,
    this.amount = '',
    this.provider = '',
    this.providerReference = '',
    this.redirectUrl = '',
    this.orderId,
    this.contributionId,
    this.equipmentOrderId,
    this.invoiceId,
    this.failureReason,
    this.failureMessageAr,
    this.lastAttemptError,
    this.lastAttemptMessageAr,
    this.paidAt,
  });

  bool get isPaid => status == 'PAID';
  bool get isFailed => status == 'FAILED';
  bool get isPending => status == 'PENDING';

  /// Paid, then given back — support's doing, never the gateway's.
  ///
  /// Unreachable inside a live payment: nothing can be refunded between opening
  /// a page and confirming it. It exists so that if one ever does arrive, it is
  /// not read as a card refusal and answered with "check your card details" —
  /// there was nothing wrong with the card.
  bool get isRefunded => status == 'REFUNDED';

  /// The bank refused the card, **and the invoice is still open**: another card
  /// on this very same payment will go through.
  ///
  /// This is the one distinction `status` cannot make on its own, and getting
  /// it wrong is the difference between "your card was declined, try another"
  /// and "we can't tell yet, check back later" — the second of which we showed
  /// a customer whose card had just been refused.
  ///
  /// It reads as PENDING because a refusal does not close a MyFatoorah invoice;
  /// the gateway keeps it payable so the customer can try again on the same
  /// page. Any non-empty code counts: MyFatoorah adds them without notice, and
  /// an unrecognised one is still a refusal.
  bool get isDeclinedRetryable => isPending && lastAttemptError != null;

  /// Whether the customer must be sent to a hosted page before confirming.
  bool get needsHostedPage => redirectUrl.isNotEmpty;

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    id: j['id'] as int? ?? 0,
    status: (j['status'] ?? '').toString().toUpperCase(),
    // Normalised on the way in, so every surface that shows a payment amount
    // agrees with every other one regardless of which endpoint it came from.
    amount: Money.format((j['amount'] ?? '').toString()),
    provider: (j['provider'] ?? '').toString(),
    providerReference: (j['provider_reference'] ?? '').toString(),
    redirectUrl: (j['redirect_url'] ?? '').toString(),
    orderId: j['order'] as int?,
    contributionId: j['contribution'] as int?,
    equipmentOrderId: j['equipment_order'] as int?,
    invoiceId: j['invoice_id'] as int?,
    failureReason: textOrNull(j['failure_reason']),
    failureMessageAr: textOrNull(j['failure_message_ar']),
    lastAttemptError: textOrNull(j['last_attempt_error']),
    lastAttemptMessageAr: textOrNull(j['last_attempt_message_ar']),
    paidAt: DateTime.tryParse((j['paid_at'] ?? '').toString()),
  );

  /// Null for absent, null for blank — a whitespace-only reason is not a reason,
  /// and letting one through would blank the screen's own fallback wording.
  static String? textOrNull(Object? value) {
    final text = (value as String?)?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  @override
  List<Object?> get props => [
    id,
    status,
    amount,
    redirectUrl,
    lastAttemptError,
  ];
}

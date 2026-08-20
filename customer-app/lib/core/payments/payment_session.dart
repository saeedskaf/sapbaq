import 'package:equatable/equatable.dart';
import 'package:sapbaq/core/utils/money.dart';
import 'package:sapbaq/features/orders/data/models/payment.dart';

/// A card the customer saved on a previous payment.
///
/// The card itself lives at the gateway; this is a handle plus just enough to
/// tell two cards apart. [token] is opaque and must never be rendered.
///
/// The backend confirms [expiryMonth] / [expiryYear] are **always null** —
/// MyFatoorah's `CustomerTokens` returns only the token, the brand and a masked
/// number. They stay in the model so the contract's shape is honest, but no UI
/// may depend on them.
class SavedCard extends Equatable {
  final String token;
  final String brand;
  final String lastFour;
  final int? expiryMonth;
  final int? expiryYear;

  const SavedCard({
    required this.token,
    required this.brand,
    required this.lastFour,
    this.expiryMonth,
    this.expiryYear,
  });

  /// What the customer reads on the row: «•••• 4242».
  String get masked => '•••• $lastFour';

  factory SavedCard.fromJson(Map<String, dynamic> j) => SavedCard(
    token: (j['token'] ?? '').toString(),
    brand: (j['brand'] ?? '').toString(),
    lastFour: (j['last_four'] ?? '').toString(),
    expiryMonth: j['expiry_month'] as int?,
    expiryYear: j['expiry_year'] as int?,
  );

  @override
  List<Object?> get props => [token, brand, lastFour];
}

/// An open embedded-checkout session: what the in-app card fields bind to.
///
/// Created by `POST /payments/session/`, which makes or reuses the same
/// `Payment` row `initiate` would — hence [paymentId] is the very same id
/// `confirm` takes. No gateway invoice exists yet; that happens at `execute`,
/// so abandoning the sheet costs nothing.
class PaymentSession extends Equatable {
  final int paymentId;
  final String sessionId;

  /// Which MyFatoorah region the session belongs to (`KWT`). The SDK needs it.
  final String countryCode;

  /// For display only — never sent back on `execute`, where the charge is
  /// always taken from the server's own record. Normalised through [Money] like
  /// every other amount the app shows.
  final String amount;

  /// When the gateway stops accepting this session, if it said. Empty when it
  /// didn't.
  ///
  /// Not used to pre-empt anything: a client clock is not a good enough reason
  /// to refuse a payment, and the server tells us plainly with
  /// `payment_rejected` when a session is spent. Kept because it is the one
  /// thing that explains *why* a sheet left open through a long phone call
  /// suddenly needs reopening.
  final String expiresAt;
  final String currency;

  /// The language the session was actually created in (`AR` / `EN`).
  ///
  /// The gateway fixes its card fields' language when the session is created —
  /// its library holds only an English path and cannot switch afterwards. So the
  /// embedded page is opened with *this*, never with whatever the app's locale
  /// happens to be by then: change the language between opening the sheet and
  /// creating the session and the two disagree, leaving an Arabic frame drawn
  /// around English inputs.
  final String language;

  final List<SavedCard> savedCards;

  const PaymentSession({
    required this.paymentId,
    required this.sessionId,
    this.countryCode = '',
    this.amount = '',
    this.currency = '',
    this.expiresAt = '',
    this.language = '',
    this.savedCards = const [],
  });

  factory PaymentSession.fromJson(Map<String, dynamic> j) => PaymentSession(
    paymentId: j['payment_id'] as int? ?? 0,
    sessionId: (j['session_id'] ?? '').toString(),
    countryCode: (j['country_code'] ?? '').toString(),
    amount: Money.format((j['amount'] ?? '').toString()),
    currency: (j['currency'] ?? '').toString(),
    expiresAt: (j['session_expires_at'] ?? '').toString(),
    language: (j['language'] ?? '').toString(),
    savedCards: (j['saved_cards'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => SavedCard.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  @override
  List<Object?> get props => [paymentId, sessionId, amount, savedCards];
}

/// The outcome of `POST /payments/execute/` — a **hint**, not a verdict.
///
/// [redirectUrl] is the field that decides what happens next, and it is the
/// whole reason embedded checkout is worth building: empty means the bank asked
/// for nothing more and no browser ever opens. `confirm` is still called either
/// way.
class PaymentExecution extends Equatable {
  final int paymentId;
  final String status;
  final int? invoiceId;

  /// A 3-D Secure challenge to host, or empty when none is needed.
  final String redirectUrl;

  /// The gateway's own reason for a refusal, ready to show. Null when there
  /// isn't one — which is most of the time.
  final String? failureReason;

  /// The same refusal in Arabic, written by the server for display. This is the
  /// one that may go on screen; [failureReason] is for tickets and logs.
  final String? failureMessageAr;

  const PaymentExecution({
    required this.paymentId,
    this.status = '',
    this.invoiceId,
    this.redirectUrl = '',
    this.failureReason,
    this.failureMessageAr,
  });

  bool get needsHostedPage => redirectUrl.isNotEmpty;

  factory PaymentExecution.fromJson(Map<String, dynamic> j) => PaymentExecution(
    paymentId: j['payment_id'] as int? ?? 0,
    status: (j['status'] ?? '').toString().toUpperCase(),
    invoiceId: j['invoice_id'] as int?,
    redirectUrl: (j['redirect_url'] ?? '').toString(),
    failureReason: Payment.textOrNull(j['failure_reason']),
    failureMessageAr: Payment.textOrNull(j['failure_message_ar']),
  );

  @override
  List<Object?> get props => [paymentId, status, invoiceId, redirectUrl];
}

/// Which methods the merchant account can actually take.
///
/// Read from the gateway rather than a constant, so Apple Pay goes live by a
/// switch in the MyFatoorah portal — no app build, no store review. Until that
/// happens the app must not draw a wallet button that would only fail.
class PaymentMethods extends Equatable {
  final bool card;
  final bool knet;
  final bool applePay;
  final bool googlePay;
  final bool stcPay;

  /// Whether the account can tokenize cards at all.
  ///
  /// False is not a preference — it means the gateway rejects the whole
  /// save-card block, so a "save this card" switch would be a control that does
  /// nothing, and `/payments/cards/` would always come back empty. A switch that
  /// silently does nothing is worse than no switch.
  final bool saveCards;

  const PaymentMethods({
    this.card = false,
    this.knet = false,
    this.applePay = false,
    this.googlePay = false,
    this.stcPay = false,
    this.saveCards = false,
  });

  /// What to assume when the call fails: the two methods that have worked since
  /// the hosted page shipped. Better a usable sheet than an empty one.
  ///
  /// Wallets are deliberately absent — assuming one that isn't live draws a
  /// button that can only fail, and the customer has no way to know why.
  static const fallback = PaymentMethods(card: true, knet: true);

  factory PaymentMethods.fromJson(Map<String, dynamic> j) => PaymentMethods(
    card: j['card'] == true,
    knet: j['knet'] == true,
    applePay: j['apple_pay'] == true,
    googlePay: j['google_pay'] == true,
    stcPay: j['stc_pay'] == true,
    saveCards: j['save_cards'] == true,
  );

  @override
  List<Object?> get props => [
    card,
    knet,
    applePay,
    googlePay,
    stcPay,
    saveCards,
  ];
}

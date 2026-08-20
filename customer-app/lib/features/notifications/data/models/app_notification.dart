import 'package:equatable/equatable.dart';

/// An inbox notification from `GET /notifications/`. The id fields are lifted
/// out of the `data` payload (when present) so a tap can deep-link to the
/// order, the support ticket, or the contribution.
///
/// [title]/[body] arrive in the request's `Accept-Language`; every row also
/// carries both copies (`title_ar`/`title_en`/…), so switching language
/// re-renders a loaded list through [titleFor]/[bodyFor] without a refetch.
class AppNotification extends Equatable {
  final int id;
  final String type;
  final String title;
  final String body;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final int? orderId;
  final int? ticketId;
  final int? contributionId;

  /// Catalogue equipment order (`equip_order.*` pushes).
  final int? equipmentRequestId;

  final String? createdAt;

  /// Whether this row has been read (backend `read`; `read_at` is when).
  final bool read;
  final String? readAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.titleAr = '',
    this.titleEn = '',
    this.bodyAr = '',
    this.bodyEn = '',
    this.orderId,
    this.ticketId,
    this.contributionId,
    this.equipmentRequestId,
    this.createdAt,
    this.read = false,
    this.readAt,
  });

  /// A copy marked read (optimistic UI before the server confirms).
  AppNotification asRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    titleAr: titleAr,
    titleEn: titleEn,
    bodyAr: bodyAr,
    bodyEn: bodyEn,
    orderId: orderId,
    ticketId: ticketId,
    contributionId: contributionId,
    equipmentRequestId: equipmentRequestId,
    createdAt: createdAt,
    read: true,
    readAt: readAt,
  );

  static int? _dataInt(dynamic data, String key) {
    final raw = data is Map ? data[key] : null;
    return raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    String str(String key) => (json[key] ?? '').toString();
    return AppNotification(
      id: json['id'] as int,
      type: (json['notification_type'] ?? '').toString(),
      title: str('title'),
      body: str('body'),
      titleAr: str('title_ar'),
      titleEn: str('title_en'),
      bodyAr: str('body_ar'),
      bodyEn: str('body_en'),
      orderId: _dataInt(data, 'order_id'),
      ticketId: _dataInt(data, 'ticket_id'),
      contributionId: _dataInt(data, 'contribution_id'),
      equipmentRequestId: _dataInt(data, 'equipment_request_id'),
      createdAt: json['created_at'] as String?,
      read: json['read'] == true,
      readAt: json['read_at'] as String?,
    );
  }

  /// The title in [languageCode] (`ar`/`en`).
  String titleFor(String languageCode) =>
      _pick(languageCode, ar: titleAr, en: titleEn, resolved: title);

  /// The body in [languageCode] (`ar`/`en`).
  String bodyFor(String languageCode) =>
      _pick(languageCode, ar: bodyAr, en: bodyEn, resolved: body);

  /// Rows sent before the backend stored both languages carry only one, so fall
  /// back to the copy the server resolved and then to the other language — a
  /// line in the wrong language beats a blank one.
  static String _pick(
    String languageCode, {
    required String ar,
    required String en,
    required String resolved,
  }) {
    final english = languageCode == 'en';
    for (final candidate in [english ? en : ar, resolved, english ? ar : en]) {
      if (candidate.isNotEmpty) return candidate;
    }
    return '';
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    body,
    titleAr,
    titleEn,
    bodyAr,
    bodyEn,
    orderId,
    ticketId,
    contributionId,
    createdAt,
    read,
    readAt,
  ];
}

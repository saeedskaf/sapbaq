import 'package:equatable/equatable.dart';

/// An inbox notification from `GET /notifications/`. The id fields are lifted
/// out of the `data` payload (when present) so a tap can deep-link to the
/// relevant order, destination, approval, or escalation (§14).
///
/// [title]/[body] arrive in the request's `Accept-Language`; every row also
/// carries both copies (`title_ar`/`title_en`/…), so switching language
/// re-renders a loaded list through [titleFor]/[bodyFor] without a refetch —
/// this inbox is a shell tab that outlives a trip to the language screen.
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
  final int? destinationId;
  final int? approvalId;
  final int? escalationId;
  final int? maintenanceCaseId;
  final int? equipmentRequestId;
  final int? waterFlagId;
  final int? contributionId;
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
    this.destinationId,
    this.approvalId,
    this.escalationId,
    this.maintenanceCaseId,
    this.equipmentRequestId,
    this.waterFlagId,
    this.contributionId,
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
    destinationId: destinationId,
    approvalId: approvalId,
    escalationId: escalationId,
    maintenanceCaseId: maintenanceCaseId,
    equipmentRequestId: equipmentRequestId,
    waterFlagId: waterFlagId,
    contributionId: contributionId,
    createdAt: createdAt,
    read: true,
    readAt: readAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    int? pick(String key) {
      final raw = data is Map ? data[key] : null;
      return raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    }

    int? pickAny(List<String> keys) {
      for (final k in keys) {
        final v = pick(k);
        if (v != null) return v;
      }
      return null;
    }

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
      orderId: pick('order_id'),
      destinationId: pick('destination_id'),
      approvalId: pick('approval_id'),
      escalationId: pick('escalation_id'),
      maintenanceCaseId: pickAny([
        'case_id',
        'maintenance_id',
        'maintenance_case_id',
      ]),
      equipmentRequestId: pickAny([
        'equipment_request_id',
        'equipment_request',
      ]),
      waterFlagId: pickAny(['water_flag_id', 'water_flag']),
      contributionId: pick('contribution_id'),
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
    destinationId,
    approvalId,
    escalationId,
    maintenanceCaseId,
    equipmentRequestId,
    waterFlagId,
    contributionId,
    createdAt,
    read,
    readAt,
  ];
}

import 'package:equatable/equatable.dart';

/// An inbox notification from `GET /notifications/`. The id fields are lifted
/// out of the `data` payload (when present) so a tap can deep-link to the
/// relevant order, destination, approval, or escalation (§14).
class AppNotification extends Equatable {
  final int id;
  final String type;
  final String title;
  final String body;
  final int? orderId;
  final int? destinationId;
  final int? approvalId;
  final int? escalationId;
  final String? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.destinationId,
    this.approvalId,
    this.escalationId,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    int? pick(String key) {
      final raw = data is Map ? data[key] : null;
      return raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    }

    return AppNotification(
      id: json['id'] as int,
      type: (json['notification_type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      orderId: pick('order_id'),
      destinationId: pick('destination_id'),
      approvalId: pick('approval_id'),
      escalationId: pick('escalation_id'),
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, title, body, orderId, destinationId, approvalId, escalationId, createdAt];
}

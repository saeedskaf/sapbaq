import 'package:equatable/equatable.dart';

/// An inbox notification from `GET /notifications/`. [orderId] / [ticketId] are
/// lifted out of the `data` payload (when present) so a tap can deep-link to the
/// order or the support ticket.
class AppNotification extends Equatable {
  final int id;
  final String type;
  final String title;
  final String body;
  final int? orderId;
  final int? ticketId;
  final String? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.ticketId,
    this.createdAt,
  });

  static int? _dataInt(dynamic data, String key) {
    final raw = data is Map ? data[key] : null;
    return raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AppNotification(
      id: json['id'] as int,
      type: (json['notification_type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      orderId: _dataInt(data, 'order_id'),
      ticketId: _dataInt(data, 'ticket_id'),
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, title, body, orderId, ticketId, createdAt];
}

import 'package:equatable/equatable.dart';

/// An inbox notification from `GET /notifications/`. [orderId] is lifted out of
/// the `data` payload (when present) so a tap can deep-link to the order.
class AppNotification extends Equatable {
  final int id;
  final String type;
  final String title;
  final String body;
  final int? orderId;
  final String? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rawOrderId = data is Map ? data['order_id'] : null;
    return AppNotification(
      id: json['id'] as int,
      type: (json['notification_type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      orderId: rawOrderId is int
          ? rawOrderId
          : int.tryParse(rawOrderId?.toString() ?? ''),
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, orderId, createdAt];
}

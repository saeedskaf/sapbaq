import 'package:equatable/equatable.dart';

/// One message in a support ticket thread. [isMine] aligns the bubble (the
/// customer's messages on one side, support's on the other).
class TicketMessage extends Equatable {
  final int id;
  final String body;
  final String sender;
  final bool isMine;
  final String? createdAt;

  const TicketMessage({
    required this.id,
    this.body = '',
    this.sender = '',
    this.isMine = false,
    this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as int? ?? 0,
      body: (json['body'] ?? '').toString(),
      sender: (json['sender'] ?? '').toString(),
      isMine: json['is_mine'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, body, sender, isMine, createdAt];
}

/// A support ticket. List items carry the summary fields; the detail response
/// also includes the [messages] thread. `status` ∈ OPEN/IN_PROGRESS/RESOLVED/
/// CLOSED; `priority` ∈ LOW/NORMAL/HIGH/URGENT.
class SupportTicket extends Equatable {
  final int id;
  final String subject;
  final String status;
  final String priority;
  final String? createdAt;
  final List<TicketMessage> messages;

  const SupportTicket({
    required this.id,
    this.subject = '',
    this.status = 'OPEN',
    this.priority = 'NORMAL',
    this.createdAt,
    this.messages = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as int,
      subject: (json['subject'] ?? '').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      priority: (json['priority'] ?? 'NORMAL').toString(),
      createdAt: json['created_at'] as String?,
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map((e) => TicketMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, subject, status, priority, createdAt, messages];
}

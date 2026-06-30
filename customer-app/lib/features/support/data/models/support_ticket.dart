import 'package:equatable/equatable.dart';

/// An image attached to a ticket message. [url] is absolute; [type] is "image".
class TicketAttachment extends Equatable {
  final String url;
  final String type;

  const TicketAttachment({required this.url, this.type = 'image'});

  bool get isImage => type == 'image';

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      url: (json['url'] ?? '').toString(),
      type: (json['type'] ?? 'image').toString(),
    );
  }

  @override
  List<Object?> get props => [url, type];
}

/// One message in a support ticket thread. [isMine] aligns the bubble;
/// [senderType] (CUSTOMER/STAFF/SYSTEM) drives how it renders — staff bubbles
/// show [senderName], SYSTEM lines render as a centered notice.
class TicketMessage extends Equatable {
  final int id;
  final String body;
  final String sender;
  final bool isMine;
  final String senderType; // CUSTOMER | STAFF | SYSTEM
  final String? senderName;
  final List<TicketAttachment> attachments;
  final String? createdAt;

  const TicketMessage({
    required this.id,
    this.body = '',
    this.sender = '',
    this.isMine = false,
    this.senderType = 'CUSTOMER',
    this.senderName,
    this.attachments = const [],
    this.createdAt,
  });

  bool get isSystem => senderType == 'SYSTEM';
  bool get isStaff => senderType == 'STAFF';

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as int? ?? 0,
      body: (json['body'] ?? '').toString(),
      sender: (json['sender'] ?? '').toString(),
      isMine: json['is_mine'] as bool? ?? false,
      senderType: (json['sender_type'] ?? 'CUSTOMER').toString(),
      senderName: json['sender_name'] as String?,
      attachments: (json['attachments'] as List<dynamic>? ?? const [])
          .map(
            (e) => TicketAttachment.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    body,
    isMine,
    senderType,
    senderName,
    attachments,
    createdAt,
  ];
}

/// The most recent message of a ticket, used for the list preview. `null` for a
/// ticket with no replies yet.
class LastMessage extends Equatable {
  final String body;
  final String senderType;
  final String? createdAt;

  const LastMessage({
    this.body = '',
    this.senderType = 'CUSTOMER',
    this.createdAt,
  });

  bool get isMine => senderType == 'CUSTOMER';

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      body: (json['body'] ?? '').toString(),
      senderType: (json['sender_type'] ?? 'CUSTOMER').toString(),
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [body, senderType, createdAt];
}

/// A support ticket. List items carry the summary fields; the detail response
/// also includes the [messages] thread. `status` ∈ OPEN/IN_PROGRESS/RESOLVED/
/// CLOSED; `category` ∈ ORDER/PAYMENT/DELIVERY/ACCOUNT/OTHER.
class SupportTicket extends Equatable {
  final int id;
  final String subject;
  final String status;
  final String category;
  final String priority;
  final int unreadCount;

  /// Whether the customer can still post a reply. False for CLOSED tickets.
  /// Defaults to true when the backend omits it (older payloads).
  final bool canReply;
  final String? createdAt;
  final String? lastActivityAt;
  final LastMessage? lastMessage;
  final List<TicketMessage> messages;

  const SupportTicket({
    required this.id,
    this.subject = '',
    this.status = 'OPEN',
    this.category = 'OTHER',
    this.priority = 'NORMAL',
    this.unreadCount = 0,
    this.canReply = true,
    this.createdAt,
    this.lastActivityAt,
    this.lastMessage,
    this.messages = const [],
  });

  bool get hasUnread => unreadCount > 0;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as int,
      subject: (json['subject'] ?? '').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      category: (json['category'] ?? 'OTHER').toString(),
      priority: (json['priority'] ?? 'NORMAL').toString(),
      unreadCount: json['unread_count'] as int? ?? 0,
      canReply: json['can_reply'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      lastActivityAt: json['last_activity_at'] as String?,
      lastMessage: json['last_message'] is Map
          ? LastMessage.fromJson(
              Map<String, dynamic>.from(json['last_message'] as Map),
            )
          : null,
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map((e) => TicketMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    subject,
    status,
    category,
    unreadCount,
    canReply,
    lastActivityAt,
    lastMessage,
    messages,
  ];
}

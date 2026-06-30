import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';

/// An escalation raised to a manager/role (`GET/POST /admin/escalations/`,
/// STAFF_APP_API_HANDOFF §9). The list returns escalations directed to me.
class Escalation extends Equatable {
  final int id;
  final int? order;
  final String orderReference;
  final StaffRef? raisedBy;
  final StaffRef? targetUser;
  final String targetRole;
  final String reason;
  final String status; // OPEN | RESOLVED
  final StaffRef? resolvedBy;
  final String? resolvedAt;
  final String? createdAt;

  const Escalation({
    required this.id,
    required this.reason,
    required this.status,
    this.order,
    this.orderReference = '',
    this.raisedBy,
    this.targetUser,
    this.targetRole = '',
    this.resolvedBy,
    this.resolvedAt,
    this.createdAt,
  });

  bool get isOpen => status == 'OPEN';

  String get shortReference => orderReference.length >= 8
      ? orderReference.substring(0, 8)
      : orderReference;

  static StaffRef? _ref(dynamic v) =>
      v is Map ? StaffRef.fromJson(Map<String, dynamic>.from(v)) : null;

  factory Escalation.fromJson(Map<String, dynamic> json) {
    return Escalation(
      id: json['id'] as int? ?? 0,
      order: json['order'] as int?,
      orderReference: (json['order_reference'] ?? '').toString(),
      raisedBy: _ref(json['raised_by']),
      targetUser: _ref(json['target_user']),
      targetRole: (json['target_role'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      resolvedBy: _ref(json['resolved_by']),
      resolvedAt: json['resolved_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, reason, order, resolvedAt];
}

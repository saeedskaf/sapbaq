import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';

/// A Maker-Checker approval request (`GET /admin/approvals/`,
/// STAFF_APP_API_HANDOFF §10). Approving executes the deferred [action].
class Approval extends Equatable {
  final int id;
  final String action; // e.g. "order.cancel"
  final String state; // PENDING | APPROVED | REJECTED | CANCELLED
  final StaffRef? maker;
  final StaffRef? checker;
  final String checkerRole;
  final String targetType; // e.g. "Order"
  final int? targetId;
  final Map<String, dynamic> payload;
  final String? amount;
  final String decisionReason;
  final String? createdAt;

  const Approval({
    required this.id,
    required this.action,
    required this.state,
    this.maker,
    this.checker,
    this.checkerRole = '',
    this.targetType = '',
    this.targetId,
    this.payload = const {},
    this.amount,
    this.decisionReason = '',
    this.createdAt,
  });

  bool get isPending => state == 'PENDING';

  /// A human-readable reason carried in the payload, when present.
  String get payloadReason => (payload['reason'] ?? '').toString();

  static StaffRef? _ref(dynamic v) => v is Map
      ? StaffRef.fromJson(Map<String, dynamic>.from(v))
      : null;

  factory Approval.fromJson(Map<String, dynamic> json) {
    return Approval(
      id: json['id'] as int? ?? 0,
      action: (json['action'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      maker: _ref(json['maker']),
      checker: _ref(json['checker']),
      checkerRole: (json['checker_role'] ?? '').toString(),
      targetType: (json['target_type'] ?? '').toString(),
      targetId: json['target_id'] as int?,
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
      amount: json['amount']?.toString(),
      decisionReason: (json['decision_reason'] ?? '').toString(),
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, action, state, targetId, decisionReason];
}

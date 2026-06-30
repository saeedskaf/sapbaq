import 'package:equatable/equatable.dart';

/// One entry in the current user's activity feed (`GET /admin/me/activity/`,
/// STAFF_APP_API_HANDOFF §8). The feed is paginated, newest first. [action] is
/// a dotted code (e.g. "destination.assigned"); map it to a label in the UI.
class ActivityEntry extends Equatable {
  final int id;
  final String action;
  final String targetType;
  final int? targetId;
  final Map<String, dynamic> payload;
  final String? createdAt;

  const ActivityEntry({
    required this.id,
    required this.action,
    this.targetType = '',
    this.targetId,
    this.payload = const {},
    this.createdAt,
  });

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    return ActivityEntry(
      id: json['id'] as int? ?? 0,
      action: (json['action'] ?? '').toString(),
      targetType: (json['target_type'] ?? '').toString(),
      targetId: json['target_id'] as int?,
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, action, targetType, targetId, createdAt];
}

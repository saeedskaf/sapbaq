import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/core/utils/distance.dart';
import 'package:sapbaq_admin/features/admin/data/models/mosque_need.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart' show StaffRef;

/// `GET /admin/marketplace/fulfilment-tasks/` — one unit of marketplace field
/// work (BACKEND_CHANGES_UNIFIED_FULFILMENT_DISPATCH §1). A WATER task settles
/// every paid contribution of one restock flag at once; an EQUIPMENT task
/// installs one funded unit. Maintenance settles via its case and CONTRACT
/// self-fulfils on payment, so neither appears here (§3).
class FulfilmentTask extends Equatable {
  final int id;
  final String kind; // WATER | EQUIPMENT
  final String status; // AWAITING_ASSIGN → ASSIGNED_TO_TEAM → ASSIGNED → DONE
  final NeedMosque? mosque;
  final StaffRef? teamLeader;
  final StaffRef? handler;

  /// Kind-specific payload: `{restock_flag_id, funded_packages, package_label}`
  /// for WATER, `{equipment_request_id, equipment_type, model}` for EQUIPMENT.
  final Map<String, dynamic> target;

  /// Settlement proof — present once the task is DONE.
  final String statement;
  final String? photo;

  /// Straight-line km to the task's mosque — present only when the list
  /// request carried the user's position (sorting doc §6).
  final double? distanceKm;

  final DateTime? createdAt;
  final DateTime? assignedToTeamAt;
  final DateTime? assignedAt;
  final DateTime? doneAt;

  const FulfilmentTask({
    required this.id,
    required this.kind,
    required this.status,
    this.mosque,
    this.teamLeader,
    this.handler,
    this.target = const {},
    this.statement = '',
    this.photo,
    this.distanceKm,
    this.createdAt,
    this.assignedToTeamAt,
    this.assignedAt,
    this.doneAt,
  });

  bool get isDone => status == 'DONE';

  factory FulfilmentTask.fromJson(Map<String, dynamic> j) {
    StaffRef? staff(Object? v) =>
        v is Map ? StaffRef.fromJson(Map<String, dynamic>.from(v)) : null;
    return FulfilmentTask(
      id: j['id'] as int? ?? 0,
      kind: (j['kind'] ?? '').toString().toUpperCase(),
      status: (j['status'] ?? '').toString().toUpperCase(),
      mosque: j['mosque'] is Map
          ? NeedMosque.fromJson(Map<String, dynamic>.from(j['mosque'] as Map))
          : null,
      teamLeader: staff(j['team_leader']),
      handler: staff(j['handler']),
      target: j['target'] is Map
          ? Map<String, dynamic>.from(j['target'] as Map)
          : const {},
      statement: (j['statement'] ?? '').toString(),
      photo: (j['photo'] as String?)?.isNotEmpty == true
          ? j['photo'] as String
          : null,
      distanceKm: parseDistanceKm(j['distance_km']),
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
      assignedToTeamAt: DateTime.tryParse(
        (j['assigned_to_team_at'] ?? '').toString(),
      ),
      assignedAt: DateTime.tryParse((j['assigned_at'] ?? '').toString()),
      doneAt: DateTime.tryParse((j['done_at'] ?? '').toString()),
    );
  }

  /// A one-line, kind-specific summary of [target] for the card — the funded
  /// package count for WATER ("3 × كرتون مياه"), the unit type for EQUIPMENT.
  String get targetSummary {
    String s(String key) => (target[key] ?? '').toString();
    switch (kind) {
      case 'WATER':
        final packages = s('funded_packages');
        final label = s('package_label');
        return [packages, label].where((e) => e.isNotEmpty).join(' × ');
      case 'EQUIPMENT':
        return s('equipment_type');
      default:
        return '';
    }
  }

  /// What this equipment task installs — the product plus the picked
  /// combination, composed by the server. Falls back to the pre-unification
  /// `model.name`. Empty for other kinds.
  String get modelName {
    String name(dynamic v) => v is Map ? (v['name'] ?? '').toString() : '';
    final parts = [
      name(target['product']),
      name(target['variant']),
    ].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' — ');
    return name(target['model']);
  }

  /// What the campaign raised, `"funded / target"` — only present on EQUIPMENT
  /// tasks, and always a fully-funded pair: since crowdfunding, an equipment
  /// task isn't created until the goal is met (crowdfunding doc, staff §2).
  /// Empty when the server didn't send the figures.
  String get fundedOfTarget {
    final funded = (target['funded_amount'] ?? '').toString();
    final goal = (target['target_amount'] ?? '').toString();
    if (funded.isEmpty || goal.isEmpty) return '';
    return '$funded / $goal';
  }

  /// Photo of what this task actually installs, full size — or null for WATER
  /// tasks. Read in order of specificity, the same order [modelName] composes
  /// in: the **picked combination** first (a colour or a tap count is exactly
  /// what the crew must arrive with), then the product, then the
  /// pre-unification `model` node.
  String? get modelImage => _imageFrom('image');

  /// The same photo for a list card, preferring each level's `image_thumb`
  /// derivative and falling back to the full-size images.
  String? get modelThumb => _imageFrom('image_thumb') ?? modelImage;

  /// Every photo of the picked combination (`target.variant.images`), in the
  /// server's order — the combination's own shot first, then its values', then
  /// the product's gallery (backend answers 2026-08-04 §2). The crew swipes
  /// through the angles of the unit they are installing; falls back to the
  /// single [modelImage] when the list isn't there.
  List<String> get modelImages {
    final variant = target['variant'];
    if (variant is Map && variant['images'] is List) {
      final urls = [
        for (final image in variant['images'] as List)
          if (image.toString().isNotEmpty) image.toString(),
      ];
      if (urls.isNotEmpty) return urls;
    }
    final single = modelImage;
    return single == null ? const [] : [single];
  }

  String? _imageFrom(String key) {
    for (final node in [
      target['variant'],
      target['product'],
      target['model'],
    ]) {
      if (node is! Map) continue;
      final value = (node[key] ?? '').toString();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    kind,
    status,
    teamLeader,
    handler,
    distanceKm,
  ];
}

/// The task lifecycle statuses, in dispatch order. `CANCELLED` is reserved by
/// the backend for a later phase.
abstract final class FulfilmentTaskEnums {
  static const statuses = [
    'AWAITING_ASSIGN',
    'ASSIGNED_TO_TEAM',
    'ASSIGNED',
    'DONE',
  ];
}

/// A dispatch action on a fulfilment task.
enum FulfilmentAction { assignLeader, assignHandler, fulfil }

/// Which actions are visible on a task, gating role capability and task
/// [status] together (dispatch doc §1 + §5). Pure (no Flutter), mirroring
/// [visibleMaintenanceActions].
///
/// - [isDesk]: the user triages (dispatch desk / global admin).
/// - [isBypass]: the regional manager (or global admin) — may assign a handler
///   past the leader and fulfil any task in scope.
/// - [isLeader]: the user is the task's assigned team leader.
/// - [isHandler]: the user is the task's assigned handler.
Set<FulfilmentAction> visibleFulfilmentActions({
  required String status,
  required bool isDesk,
  required bool isBypass,
  required bool isLeader,
  required bool isHandler,
}) {
  return {
    if ((isDesk || isBypass) && status == 'AWAITING_ASSIGN')
      FulfilmentAction.assignLeader,
    // The regional/global manager may skip the leader and assign a handler
    // straight on a new task (dispatch answers §Q4 — both, direct on
    // AWAITING_ASSIGN); the desk (RO/SA) still needs a leader first.
    if (isBypass && status == 'AWAITING_ASSIGN') FulfilmentAction.assignHandler,
    if ((isLeader || isBypass) && status == 'ASSIGNED_TO_TEAM')
      FulfilmentAction.assignHandler,
    if ((isHandler || isLeader || isBypass) && status == 'ASSIGNED')
      FulfilmentAction.fulfil,
  };
}

import 'package:equatable/equatable.dart';

/// Which of the three things a row is. Everything else on the row is already
/// composed by the server, so this only drives the badge, the icon and the
/// deep link — it is what replaces the tabs we removed (delivery §5.1).
enum ActivityKind {
  productOrder,
  equipmentRequest,
  contribution,
  unknown;

  static ActivityKind from(String? raw) => switch (raw?.toUpperCase()) {
    'PRODUCT_ORDER' => ActivityKind.productOrder,
    'EQUIPMENT_REQUEST' => ActivityKind.equipmentRequest,
    'CONTRIBUTION' => ActivityKind.contribution,
    _ => ActivityKind.unknown,
  };
}

/// One bucket across three different lifecycles. The app colours and orders by
/// this alone — it deliberately knows nothing about the thirty underlying
/// statuses behind it (delivery §5.1).
enum ActivityStatusGroup {
  actionRequired,
  inProgress,
  done,
  cancelled;

  static ActivityStatusGroup from(String? raw) => switch (raw?.toUpperCase()) {
    'ACTION_REQUIRED' => ActivityStatusGroup.actionRequired,
    'DONE' => ActivityStatusGroup.done,
    'CANCELLED' => ActivityStatusGroup.cancelled,
    _ => ActivityStatusGroup.inProgress,
  };
}

/// What the row asks the donor to do, if anything. `PAY` may carry a
/// [deadline] (the equipment window, a contribution hold) or none at all — an
/// unpaid product order has no server-side clock, so the button shows without
/// a countdown.
class ActivityAction extends Equatable {
  final String type;
  final DateTime? deadline;

  const ActivityAction({required this.type, this.deadline});

  bool get isPay => type.toUpperCase() == 'PAY';

  /// Recomputed on read rather than counted down locally, so it survives the
  /// app being backgrounded.
  Duration? get timeLeft {
    final at = deadline;
    if (at == null) return null;
    final left = at.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  static ActivityAction? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final type = (raw['type'] ?? '').toString();
    if (type.isEmpty) return null;
    return ActivityAction(
      type: type,
      deadline: DateTime.tryParse((raw['deadline'] ?? '').toString()),
    );
  }

  @override
  List<Object?> get props => [type, deadline];
}

/// Where tapping the row goes. The three detail screens kept their own
/// endpoints, so this only names which one.
class ActivityLink extends Equatable {
  final String route;
  final int id;

  const ActivityLink({required this.route, required this.id});

  static ActivityLink? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final route = (raw['route'] ?? '').toString();
    final id = raw['id'] as int?;
    if (route.isEmpty || id == null) return null;
    return ActivityLink(route: route, id: id);
  }

  @override
  List<Object?> get props => [route, id];
}

/// The mosque a row is for. Always set in normal cases (a contribution's mosque
/// comes from its target), but treated as nullable per the contract's warning.
class ActivityMosque extends Equatable {
  final int id;
  final String name;
  final bool isMostNeeded;

  const ActivityMosque({
    required this.id,
    this.name = '',
    this.isMostNeeded = false,
  });

  factory ActivityMosque.fromJson(Map<String, dynamic> j) => ActivityMosque(
    id: j['id'] as int? ?? 0,
    name: (j['name'] ?? '').toString(),
    isMostNeeded: j['is_most_needed'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, name, isMostNeeded];
}

/// One row of «طلباتي» — a product order, an equipment request or a marketplace
/// contribution, in one shape.
///
/// **Every string here is composed and translated server-side** ([title],
/// [subtitle], [statusLabel]): the app renders them as they arrive and never
/// assembles a label of its own, so the wording matches the invoice and the
/// notification exactly (delivery §5.1).
class ActivityRow extends Equatable {
  final ActivityKind kind;
  final int id;
  final String reference;
  final DateTime? createdAt;
  final String title;
  final String subtitle;
  final String? image;
  final String amount;
  final ActivityMosque? mosque;
  final String status;
  final ActivityStatusGroup statusGroup;
  final String statusLabel;
  final ActivityAction? action;
  final ActivityLink? deepLink;

  const ActivityRow({
    required this.kind,
    required this.id,
    this.reference = '',
    this.createdAt,
    this.title = '',
    this.subtitle = '',
    this.image,
    this.amount = '0',
    this.mosque,
    this.status = '',
    this.statusGroup = ActivityStatusGroup.inProgress,
    this.statusLabel = '',
    this.action,
    this.deepLink,
  });

  bool get needsAction => statusGroup == ActivityStatusGroup.actionRequired;

  factory ActivityRow.fromJson(Map<String, dynamic> j) => ActivityRow(
    kind: ActivityKind.from(j['kind'] as String?),
    id: j['id'] as int? ?? 0,
    reference: (j['reference'] ?? '').toString(),
    createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
    title: (j['title'] ?? '').toString(),
    subtitle: (j['subtitle'] ?? '').toString(),
    image: (j['image'] as String?)?.isEmpty ?? true
        ? null
        : j['image'] as String,
    amount: (j['amount'] ?? '0').toString(),
    mosque: j['mosque'] is Map
        ? ActivityMosque.fromJson(Map<String, dynamic>.from(j['mosque'] as Map))
        : null,
    status: (j['status'] ?? '').toString(),
    statusGroup: ActivityStatusGroup.from(j['status_group'] as String?),
    statusLabel: (j['status_label'] ?? '').toString(),
    action: ActivityAction.fromJson(j['action']),
    deepLink: ActivityLink.fromJson(j['deep_link']),
  );

  @override
  List<Object?> get props => [
    kind,
    id,
    status,
    statusGroup,
    statusLabel,
    action,
    amount,
  ];
}

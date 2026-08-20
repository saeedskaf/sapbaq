import 'package:equatable/equatable.dart';

/// How many items in each operations-center queue are **waiting on the signed-in
/// user** — the number the nav badge shows, so staff see work waiting without
/// opening anything.
///
/// Comes straight from `GET /admin/ops/counts/`, which encodes the per-role
/// "needs my action" logic server-side: the desk's un-dispatched maintenance,
/// a team leader's cases awaiting distribution/verification, a handler's own
/// in-progress work, etc. A queue the role can't act on comes back 0, so the
/// badge stays a truthful call to action.
class OpsCounts extends Equatable {
  final int maintenance;
  final int waterFlags;
  final int equipmentRequests;

  /// Open fulfilment tasks in the user's scope (the field kept its old name
  /// but changed meaning — unified-dispatch doc §7).
  final int contributions;

  /// Catalogue equipment orders awaiting this user's action — the approval for
  /// a manager, the install for the leader/handler it sits with. Role-scoped
  /// like every other field here, which is exactly what the field was asked
  /// for and shipped as (backend answers §6).
  final int catalogOrders;

  const OpsCounts({
    this.maintenance = 0,
    this.waterFlags = 0,
    this.equipmentRequests = 0,
    this.contributions = 0,
    this.catalogOrders = 0,
  });

  /// `GET /admin/ops/counts/` — each field is already the role-scoped
  /// "needs my action" count; a queue the role can't act on comes back 0.
  factory OpsCounts.fromJson(Map<String, dynamic> j) => OpsCounts(
    maintenance: j['maintenance'] as int? ?? 0,
    waterFlags: j['water_flags'] as int? ?? 0,
    equipmentRequests: j['equipment_requests'] as int? ?? 0,
    contributions: j['contributions'] as int? ?? 0,
    catalogOrders: j['catalog_orders'] as int? ?? 0,
  );

  int get total =>
      maintenance +
      waterFlags +
      equipmentRequests +
      contributions +
      catalogOrders;

  @override
  List<Object?> get props => [
    maintenance,
    waterFlags,
    equipmentRequests,
    contributions,
    catalogOrders,
  ];
}

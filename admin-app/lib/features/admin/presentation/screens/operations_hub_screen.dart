import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/theme/theme_colors.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/models/ops_counts.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/ops_counts_cubit.dart';
import 'package:sapbaq_admin/features/admin/presentation/widgets/ops_entry_card.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// The operations center: a role-gated hub of moderation/dispatch queues,
/// carried as a tab by every staff shell (admin / retail / driver) — this is
/// where staff work, so it opens on how much is waiting for them.
///
/// The queues are grouped by the *kind* of work they are (decide → execute →
/// create) rather than listed flat, each card says what its queue holds and
/// what the signed-in role does with it, and a "how operations flow" sheet
/// lays out the request → approval → funding → assignment → proof chain: a
/// staff member on their first shift should be able to read this screen
/// without a briefing.
///
/// Each card is shown only when the signed-in role can act on that queue, and
/// carries its own pending count. Also reachable pushed over any shell at
/// `/ops` (the shell-agnostic deep-link entry) — hence the [isTab] switch for
/// the bits only the tab needs.
class OperationsHubScreen extends StatefulWidget {
  /// True when shown as a shell tab: no back button, and the floating nav bar
  /// needs clearance under the list.
  final bool isTab;

  const OperationsHubScreen({super.key, this.isTab = false});

  @override
  State<OperationsHubScreen> createState() => _OperationsHubScreenState();
}

class _OperationsHubScreenState extends State<OperationsHubScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh on every visit: the queues move while the user is elsewhere in
    // the app, and a stale badge is worse than a slow one.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (!mounted) return;
    context.read<OpsCountsCubit>().load(context.read<AuthBloc>().state.user);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.read<AuthBloc>().state.user;

    return Scaffold(
      appBar: AppBar(
        title: TextCustom.subheading(text: l10n.opsTitle),
        automaticallyImplyLeading: !widget.isTab,
        actions: [
          IconButton(
            tooltip: l10n.opsHowItWorks,
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => showOpsFlowSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<OpsCountsCubit, OpsCountsState>(
        builder: (context, state) {
          final sections = _sections(l10n, user, state);

          if (sections.isEmpty) {
            return EmptyView(
              message: l10n.opsNoQueues,
              icon: Icons.dashboard_customize_outlined,
            );
          }

          return RefreshIndicator(
            color: context.colors.primary,
            onRefresh: () async => _load(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                widget.isTab ? floatingNavBarClearance(context) : 24,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _Workload(
                  counts: state.counts,
                  loading: state.loading,
                  user: user,
                ),
                for (final section in sections) ...[
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: section.title,
                    description: section.description,
                  ),
                  const SizedBox(height: 10),
                  ...section.cards,
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// The role's queues, grouped by what the user actually does with them. A
  /// section holding no card this role may open is dropped whole.
  List<_Section> _sections(
    AppLocalizations l10n,
    User? user,
    OpsCountsState state,
  ) {
    final counts = state.counts;

    // "3 items need your action" while work waits, a quiet line when it
    // doesn't, and the loading text until the first fetch lands — so a card
    // never leaves the reader guessing what a missing number meant.
    String status(int count) => state.loading
        ? l10n.opsUpdating
        : (count > 0 ? l10n.opsPendingTotal(count) : l10n.opsNothingHere);
    bool active(int count) => !state.loading && count > 0;

    // Two queues sit in a different section per role: maintenance is a triage
    // decision at the desk but assigned field work to a leader/handler, and a
    // catalogue purchase is the manager's approval but an installation to the
    // field. Filing each card under the work *this* reader does is what keeps
    // the section headings honest.
    final decidesMaintenance = user?.canTriageMaintenance == true;
    final decidesCatalog = user?.canProvisionDirect == true;

    final maintenanceCard = user?.canAccessMaintenance != true
        ? null
        : OpsEntryCard(
            icon: Icons.build_rounded,
            title: l10n.mtTitle,
            description: _maintenanceDescription(l10n, user),
            status: status(counts.maintenance),
            statusActive: active(counts.maintenance),
            onTap: () => _open(AppRoutes.opsMaintenanceName),
          );

    // Customer catalogue purchases. `catalog_orders` was asked for — and
    // shipped — as "what awaits this user's action" like every other counter
    // (payments/catalogue round §6), so it is read the same way here: the
    // manager's approvals, the leader's and handler's installs.
    final catalogCard = user?.canAccessOperations != true
        ? null
        : OpsEntryCard(
            icon: Icons.shopping_bag_outlined,
            title: l10n.coTitle,
            description: _catalogDescription(l10n, user),
            status: status(counts.catalogOrders),
            statusActive: active(counts.catalogOrders),
            onTap: () => _open(AppRoutes.opsCatalogOrdersName),
          );

    final decide = <Widget>[
      if (user?.canModerateWaterFlags == true)
        OpsEntryCard(
          icon: Icons.water_drop_rounded,
          title: l10n.opsWaterFlags,
          description: l10n.opsWaterFlagsDesc,
          status: status(counts.waterFlags),
          statusActive: active(counts.waterFlags),
          onTap: () => _open(AppRoutes.opsWaterFlagsName),
        ),
      if (user?.canApproveEquipment == true || user?.canCancelEquipment == true)
        OpsEntryCard(
          icon: Icons.kitchen_rounded,
          title: l10n.opsEquipmentRequests,
          description: l10n.opsEquipmentRequestsDesc,
          status: status(counts.equipmentRequests),
          statusActive: active(counts.equipmentRequests),
          onTap: () => _open(AppRoutes.opsEquipmentRequestsName),
        ),
      if (maintenanceCard != null && decidesMaintenance) maintenanceCard,
      if (catalogCard != null && decidesCatalog) catalogCard,
    ];

    final execute = <Widget>[
      if (maintenanceCard != null && !decidesMaintenance) maintenanceCard,
      // The marketplace field-work queue: `counts.contributions` now counts
      // open fulfilment tasks (unified-dispatch doc §7), so the card opens the
      // task queue; the view-only contributions ledger hangs off that screen.
      if (user?.canFulfilContribution == true)
        OpsEntryCard(
          icon: Icons.fact_check_rounded,
          title: l10n.ftTitle,
          description: _tasksDescription(l10n, user),
          status: status(counts.contributions),
          statusActive: active(counts.contributions),
          onTap: () => _open(AppRoutes.opsFulfilmentTasksName),
        ),
      if (catalogCard != null && !decidesCatalog) catalogCard,
    ];

    final create = <Widget>[
      // Not a queue — the manager's way in to raising a need himself, so it
      // carries no waiting count and sits in its own section instead of
      // pretending to be a workload.
      if (user?.canProvisionDirect == true)
        OpsEntryCard(
          icon: Icons.add_circle_outline_rounded,
          title: l10n.dpTitle,
          description: l10n.dpDesc,
          onTap: () => _open(AppRoutes.opsDirectName),
        ),
    ];

    return [
      if (decide.isNotEmpty)
        _Section(
          title: l10n.opsSectionApprovals,
          description: l10n.opsSectionApprovalsDesc,
          cards: decide,
        ),
      if (execute.isNotEmpty)
        _Section(
          title: l10n.opsSectionField,
          description: l10n.opsSectionFieldDesc,
          cards: execute,
        ),
      if (create.isNotEmpty)
        _Section(
          title: l10n.opsSectionCreate,
          description: l10n.opsSectionCreateDesc,
          cards: create,
        ),
    ];
  }

  /// The queues live outside the shell, so they're always pushed over it.
  void _open(String name) => context.pushNamed(name);
}

// --- Per-role card copy -----------------------------------------------------
// The three shared queues mean different work to each role that can open them
// (the desk triages what a leader distributes and a handler executes), so the
// card explains the reader's own job rather than the queue's whole lifecycle.
// The tests of these getters are the same ones that gate the cards above.

String _maintenanceDescription(AppLocalizations l10n, User? user) {
  if (user?.canTriageMaintenance == true) return l10n.mtDescTriage;
  if (user?.canClaimMaintenance == true) return l10n.mtDescLeader;
  return l10n.mtDescHandler;
}

String _tasksDescription(AppLocalizations l10n, User? user) {
  if (user?.canAssignTaskLeader == true) return l10n.ftDescDispatch;
  if (user?.userType == User.teamLeader) return l10n.ftDescLeader;
  return l10n.ftDescHandler;
}

String _catalogDescription(AppLocalizations l10n, User? user) {
  // Approving is the manager's call (the same permission that gates direct
  // provision); leaders and handlers install; every other role only watches.
  if (user?.canProvisionDirect == true) return l10n.coDesc;
  if (user?.userType == User.teamLeader || user?.isServiceHandler == true) {
    return l10n.coDescField;
  }
  return l10n.coDescWatch;
}

/// A group of hub cards with the heading that says what they have in common —
/// "needs your decision", "execution & follow-up", "raise a request".
class _Section {
  final String title;
  final String description;
  final List<Widget> cards;

  const _Section({
    required this.title,
    required this.description,
    required this.cards,
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String description;

  const _SectionHeader({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 15,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextCustom(
                  text: title,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          TextCustom(
            text: description,
            fontSize: 12,
            color: context.colors.textHint,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

/// The headline: one number for everything waiting on this user, plus the role
/// and area that decide which queues are listed below — the two facts a new
/// staff member needs before the rest of the screen makes sense.
class _Workload extends StatelessWidget {
  final OpsCounts counts;
  final bool loading;
  final User? user;

  const _Workload({
    required this.counts,
    required this.loading,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final total = counts.total;
    final clear = total == 0 && !loading;

    final scope = [
      if (user?.roleDisplay.isNotEmpty == true) user!.roleDisplay,
      if (user?.governorate?.name.isNotEmpty == true)
        l10n.opsRoleScope(user!.governorate!.name),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: clear ? colors.surfaceVariant : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _TotalBadge(total: total, clear: clear, loading: loading),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      text: loading
                          ? l10n.opsUpdating
                          : (clear
                                ? l10n.opsAllClear
                                : l10n.opsPendingTotal(total)),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 3),
                    TextCustom(
                      text: clear ? l10n.opsAllClearDesc : l10n.opsSubtitle,
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (scope.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: colors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextCustom(
                    text: scope,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The total, on a surface tile so it reads as the screen's one number: a
/// spinner until the first fetch lands, a tick once every queue is clear.
class _TotalBadge extends StatelessWidget {
  final int total;
  final bool clear;
  final bool loading;

  const _TotalBadge({
    required this.total,
    required this.clear,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: colors.primary,
              ),
            )
          : (clear
                ? Icon(Icons.check_rounded, size: 28, color: colors.primary)
                : TextCustom(
                    text: total > 99 ? '99+' : '$total',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  )),
    );
  }
}

/// "How operations flow": the request → approval → funding → assignment →
/// proof chain that every queue on this screen is one stage of. Opened from
/// the hub's app bar, so the flow can be looked up instead of inferred.
Future<void> showOpsFlowSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final colors = context.colors;
  final steps = <(String, String)>[
    (l10n.opsHowStep1, l10n.opsHowStep1Desc),
    (l10n.opsHowStep2, l10n.opsHowStep2Desc),
    (l10n.opsHowStep3, l10n.opsHowStep3Desc),
    (l10n.opsHowStep4, l10n.opsHowStep4Desc),
    (l10n.opsHowStep5, l10n.opsHowStep5Desc),
  ];

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            TextCustom.subheading(text: l10n.opsHowItWorks),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      _FlowStep(
                        number: i + 1,
                        title: steps[i].$1,
                        description: steps[i].$2,
                        isLast: i == steps.length - 1,
                      ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextCustom(
                        text: l10n.opsHowFooter,
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One numbered stage of the flow sheet, joined to the next by a connector so
/// the five steps read as a chain rather than a list.
class _FlowStep extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  final bool isLast;

  const _FlowStep({
    required this.number,
    required this.title,
    required this.description,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: TextCustom(
                  text: '$number',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: colors.textSecondary,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: colors.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextCustom(
                    text: title,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  const SizedBox(height: 4),
                  TextCustom(
                    text: description,
                    fontSize: 12.5,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

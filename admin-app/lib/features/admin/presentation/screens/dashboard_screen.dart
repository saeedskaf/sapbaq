import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/admin/data/admin_repository.dart';
import 'package:sapbaq_admin/features/admin/data/models/dashboard_summary.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/dashboard_cubit.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq_admin/features/shared/presentation/app_card.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Daily summary tab (§6): role-scoped order tallies, completion rate, SLA, and
/// a link into the activity feed (§8).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DashboardCubit(context.read<AdminRepository>())..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: TextCustom.subheading(text: l10n.dashboardTitle)),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.status == LoadStatus.loading && state.summary == null) {
            return const LoadingView();
          }
          if (state.status == LoadStatus.failure && state.summary == null) {
            return ErrorView(
              message: state.message ?? l10n.genericError,
              retryLabel: l10n.retry,
              onRetry: () => context.read<DashboardCubit>().load(),
            );
          }
          final summary = state.summary;
          if (summary == null) return const SizedBox.shrink();
          final user = context.read<AuthBloc>().state.user;
          final canLookup = user?.canLookupCustomerHistory ?? false;
          final canSuspend = user?.canSuspendProductAvailability ?? false;
          return RefreshIndicator(
            color: ColorsCustom.primary,
            onRefresh: () => context.read<DashboardCubit>().load(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                floatingNavBarClearance(context),
              ),
              children: [
                _StatGrid(orders: summary.orders, l10n: l10n),
                const SizedBox(height: 12),
                _CompletionCard(rate: summary.completionRate, l10n: l10n),
                const SizedBox(height: 12),
                _SlaCard(sla: summary.sla, l10n: l10n),
                const SizedBox(height: 12),
                _DashboardTile(
                  icon: Icons.history_rounded,
                  label: l10n.activityTitle,
                  onTap: () => context.pushNamed(AppRoutes.adminActivityName),
                ),
                const SizedBox(height: 12),
                _DashboardTile(
                  icon: Icons.fact_check_outlined,
                  label: l10n.approvalsTitle,
                  onTap: () => context.pushNamed(AppRoutes.adminApprovalsName),
                ),
                const SizedBox(height: 12),
                _DashboardTile(
                  icon: Icons.campaign_outlined,
                  label: l10n.escalationsTitle,
                  onTap: () => context.pushNamed(AppRoutes.adminEscalationsName),
                ),
                if (canLookup) ...[
                  const SizedBox(height: 12),
                  _DashboardTile(
                    icon: Icons.person_search_outlined,
                    label: l10n.customerLookupTitle,
                    onTap: () => context.pushNamed(
                      AppRoutes.adminCustomerLookupName,
                    ),
                  ),
                ],
                if (canSuspend) ...[
                  const SizedBox(height: 12),
                  _DashboardTile(
                    icon: Icons.inventory_2_outlined,
                    label: l10n.productsTitle,
                    onTap: () =>
                        context.pushNamed(AppRoutes.adminProductsName),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final DashboardOrders orders;
  final AppLocalizations l10n;
  const _StatGrid({required this.orders, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
        label: l10n.dashNew,
        value: orders.newOrders,
        icon: Icons.fiber_new_outlined,
        color: ColorsCustom.warning,
      ),
      _StatTile(
        label: l10n.dashAwaiting,
        value: orders.awaitingAssignment,
        icon: Icons.assignment_late_outlined,
        color: ColorsCustom.secondary,
      ),
      _StatTile(
        label: l10n.dashAssigned,
        value: orders.assigned,
        icon: Icons.local_shipping_outlined,
        color: ColorsCustom.primary,
      ),
      _StatTile(
        label: l10n.dashCompleted,
        value: orders.completed,
        icon: Icons.check_circle_outline,
        color: ColorsCustom.success,
      ),
      _StatTile(
        label: l10n.dashCancelled,
        value: orders.cancelled,
        icon: Icons.cancel_outlined,
        color: ColorsCustom.error,
      ),
      _StatTile(
        label: l10n.dashAll,
        value: orders.all,
        icon: Icons.receipt_long_outlined,
        color: ColorsCustom.textSecondary,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles)
              SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: '$value',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                const SizedBox(height: 2),
                TextCustom(
                  text: label,
                  fontSize: 12,
                  color: ColorsCustom.textSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final double rate; // 0..1
  final AppLocalizations l10n;
  const _CompletionCard({required this.rate, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final pct = (rate.clamp(0, 1) * 100).round();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextCustom(
                text: l10n.completionRate,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              const Spacer(),
              TextCustom(
                text: '$pct%',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ColorsCustom.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate.clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: ColorsCustom.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(ColorsCustom.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlaCard extends StatelessWidget {
  final DashboardSla sla;
  final AppLocalizations l10n;
  const _SlaCard({required this.sla, required this.l10n});

  String _minutes(double? v) =>
      v == null ? '—' : l10n.minutesValue(v.toStringAsFixed(1));

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(
            text: l10n.slaTitle,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 12),
          _SlaRow(
            label: l10n.slaAvgConfirm,
            value: _minutes(sla.avgMinutesToConfirm),
          ),
          const SizedBox(height: 8),
          _SlaRow(
            label: l10n.slaAvgDeliver,
            value: _minutes(sla.avgMinutesToDeliver),
          ),
          const SizedBox(height: 8),
          _SlaRow(
            label: l10n.slaSample,
            value: '${sla.deliveredSample}',
          ),
        ],
      ),
    );
  }
}

class _SlaRow extends StatelessWidget {
  final String label;
  final String value;
  const _SlaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextCustom(
            text: label,
            fontSize: 13.5,
            color: ColorsCustom.textSecondary,
          ),
        ),
        TextCustom(text: value, fontSize: 14, fontWeight: FontWeight.w700),
      ],
    );
  }
}

/// A tappable navigation row on the dashboard (activity, customer lookup, …).
class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorsCustom.secondaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ColorsCustom.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextCustom(
              text: label,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: ColorsCustom.textHint,
            size: 22,
          ),
        ],
      ),
    );
  }
}

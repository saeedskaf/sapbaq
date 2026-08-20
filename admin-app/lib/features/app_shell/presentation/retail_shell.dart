import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/ops_counts_cubit.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Retail-operator (LV3) shell: Customer Search / Operations / Profile
/// (FLUTTER_TASKS T1). The order/dashboard screens return empty lists / 403 for
/// this role so they stay hidden, but the operator is part of the dispatch desk
/// — the operations center is his moderation queue, so it gets a tab.
class RetailShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RetailShell({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The hub itself loads the counts on every visit; here we only mirror them.
    final pending = context.watch<OpsCountsCubit>().state.counts.total;
    return Scaffold(
      extendBody: true,
      body: FloatingBottomInset(extraInset: 0, child: navigationShell),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: [
          FloatingNavItem(
            icon: Icons.person_search_outlined,
            activeIcon: Icons.person_search,
            label: l10n.navCustomerSearch,
          ),
          FloatingNavItem(
            icon: Icons.dashboard_customize_outlined,
            activeIcon: Icons.dashboard_customize_rounded,
            label: l10n.navOperations,
            badgeCount: pending,
          ),
          FloatingNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}

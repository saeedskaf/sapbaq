import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/ops_counts_cubit.dart';
import 'package:sapbaq_admin/features/notifications/presentation/bloc/notifications_badge_cubit.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Admin app shell: Dashboard / Operations / Orders / Notifications / Profile
/// tabs with preserved per-tab navigation state and the shared frosted floating
/// nav bar.
///
/// The dashboard leads as the overview; the operations badge stays the app's
/// standing answer to "is anything waiting on me?" — visible from every tab
/// without opening it.
class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShell({super.key, required this.navigationShell});

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
    final unread = context.watch<NotificationsBadgeCubit>().state;
    return Scaffold(
      extendBody: true,
      body: FloatingBottomInset(extraInset: 0, child: navigationShell),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: [
          FloatingNavItem(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights_rounded,
            label: l10n.navDashboard,
          ),
          FloatingNavItem(
            icon: Icons.dashboard_customize_outlined,
            activeIcon: Icons.dashboard_customize_rounded,
            label: l10n.navOperations,
            badgeCount: pending,
          ),
          FloatingNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            label: l10n.navOrders,
          ),
          FloatingNavItem(
            icon: Icons.notifications_none_rounded,
            activeIcon: Icons.notifications_rounded,
            label: l10n.navNotifications,
            badgeCount: unread,
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/features/admin/presentation/bloc/ops_counts_cubit.dart';
import 'package:sapbaq_admin/features/notifications/presentation/bloc/notifications_badge_cubit.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Driver (workshop) app shell: Deliveries / Operations / Notifications /
/// Profile tabs with preserved per-tab navigation state and the shared frosted
/// floating nav bar.
class DriverShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DriverShell({super.key, required this.navigationShell});

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
            icon: Icons.local_shipping_outlined,
            activeIcon: Icons.local_shipping,
            label: l10n.navDeliveries,
          ),
          FloatingNavItem(
            icon: Icons.dashboard_customize_outlined,
            activeIcon: Icons.dashboard_customize_rounded,
            label: l10n.navOperations,
            badgeCount: pending,
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

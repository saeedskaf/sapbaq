import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/features/notifications/presentation/bloc/notifications_badge_cubit.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Mosque-representative shell: My Mosque / My Reports / Notifications /
/// Profile. Report-only — no staff areas (ADMIN_APP_BACKEND_INTEGRATION §1).
class RepShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RepShell({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unread = context.watch<NotificationsBadgeCubit>().state;
    return Scaffold(
      extendBody: true,
      body: FloatingBottomInset(extraInset: 0, child: navigationShell),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: [
          FloatingNavItem(
            icon: Icons.mosque_outlined,
            activeIcon: Icons.mosque,
            label: l10n.repNavMosque,
          ),
          FloatingNavItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            label: l10n.repNavReports,
          ),
          FloatingNavItem(
            icon: Icons.notifications_none,
            activeIcon: Icons.notifications,
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

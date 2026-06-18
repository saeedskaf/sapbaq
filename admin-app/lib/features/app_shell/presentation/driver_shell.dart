import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Driver (workshop) app shell: Deliveries / Notifications / Profile tabs with
/// preserved per-tab navigation state and the shared frosted floating nav bar.
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
            icon: Icons.notifications_none_rounded,
            activeIcon: Icons.notifications_rounded,
            label: l10n.navNotifications,
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

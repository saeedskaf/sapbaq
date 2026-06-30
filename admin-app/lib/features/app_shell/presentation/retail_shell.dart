import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

/// Retail-operator (LV3) shell: Customer Search / Profile only (FLUTTER_TASKS
/// T1). Every other staff screen returns empty lists / 403 for this role, so we
/// hide them and give it a focused two-tab app.
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
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}

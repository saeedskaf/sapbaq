import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/marketplace/data/marketplace_repository.dart';
import 'package:sapbaq/features/marketplace/presentation/bloc/marketplace_cubit.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/equipment_tab.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/maintenance_tab.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/water_tab.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// The marketplace's three feeds, in tab order. The slug is what a deep link
/// (a banner today, a push tomorrow) names the tab by.
enum MarketplaceTab {
  water('water'),
  maintenance('maintenance'),
  equipment('equipment');

  final String slug;
  const MarketplaceTab(this.slug);

  /// Resolves a `?tab=` value; anything unrecognized falls back to water, the
  /// first tab, so a bad link still lands somewhere sensible.
  static MarketplaceTab fromSlug(String? slug) => MarketplaceTab.values
      .firstWhere((t) => t.slug == slug, orElse: () => MarketplaceTab.water);
}

/// The Mosque-Needs marketplace ("live"): three tabs of approved, real needs —
/// bottled water, maintenance, equipment. Water and maintenance are buy-now;
/// equipment is crowdfunded by several donors towards one goal.
class MarketplaceScreen extends StatelessWidget {
  /// Which tab to open on. Null keeps the first (water).
  final MarketplaceTab? initialTab;

  const MarketplaceScreen({super.key, this.initialTab});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (_) => MarketplaceCubit(context.read<MarketplaceRepository>()),
      child: DefaultTabController(
        length: 3,
        initialIndex: (initialTab ?? MarketplaceTab.water).index,
        child: Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            title: TextCustom.subheading(text: l10n.mosqueNeedsTitle),
            iconTheme: IconThemeData(color: context.colors.textPrimary),
            bottom: TabBar(
              labelColor: context.colors.primary,
              unselectedLabelColor: context.colors.textSecondary,
              indicatorColor: context.colors.primary,
              tabs: [
                Tab(
                  text: l10n.tabWater,
                  icon: const Icon(Icons.water_drop_rounded),
                ),
                Tab(
                  text: l10n.tabMaintenance,
                  icon: const Icon(Icons.build_rounded),
                ),
                Tab(
                  text: l10n.tabEquipment,
                  icon: const Icon(Icons.kitchen_rounded),
                ),
              ],
            ),
          ),
          body: const TabBarView(
            children: [WaterTab(), MaintenanceTab(), EquipmentTab()],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/auth/auth_guard.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/marketplace/data/marketplace_repository.dart';
import 'package:sapbaq/features/orders/data/payment_repository.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';
import 'package:sapbaq/features/marketplace/presentation/bloc/marketplace_cubit.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/buy_now.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/marketplace_card.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class MaintenanceTab extends StatefulWidget {
  const MaintenanceTab({super.key});

  @override
  State<MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<MaintenanceTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<MarketplaceCubit>();
    if (cubit.state.maintenanceStatus == LoadStatus.initial) {
      cubit.loadMaintenance();
    }
  }

  void _reload() => context.read<MarketplaceCubit>().loadMaintenance();
  Future<void> _reloadFuture() async => _reload();

  Future<void> _run(Future<ContributionResult> Function() contribute) async {
    if (!ensureAuthenticated(context)) return;
    final l10n = AppLocalizations.of(context)!;
    final res = await runBuyNow(
      context,
      repo: context.read<MarketplaceRepository>(),
      payments: context.read<PaymentRepository>(),
      title: l10n.mosqueNeedsTitle,
      contribute: contribute,
    );
    if (mounted) handleBuyNowResult(context, res, reload: _reload);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      buildWhen: (a, b) =>
          a.maintenanceStatus != b.maintenanceStatus ||
          a.maintenance != b.maintenance,
      builder: (context, state) {
        switch (state.maintenanceStatus) {
          case LoadStatus.initial:
          case LoadStatus.loading:
            return const LoadingView();
          case LoadStatus.failure:
            return ErrorView(
              message: state.maintenanceError ?? l10n.comingSoon,
              retryLabel: l10n.retry,
              onRetry: _reload,
            );
          case LoadStatus.success:
            if (state.maintenance.isEmpty) {
              return EmptyView(
                message: l10n.emptyMaintenance,
                icon: Icons.build_outlined,
              );
            }
            return RefreshIndicator(
              color: context.colors.primary,
              onRefresh: _reloadFuture,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.maintenance.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _MaintenanceCard(
                  listing: state.maintenance[i],
                  onRepair: () => _run(
                    () => context
                        .read<MarketplaceRepository>()
                        .contributeMaintenance(
                          caseId: state.maintenance[i].caseId,
                        ),
                  ),
                  onContract: () => _run(
                    () => context
                        .read<MarketplaceRepository>()
                        .contributeContract(
                          equipmentId: state.maintenance[i].equipmentId,
                        ),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final MaintenanceListing listing;
  final VoidCallback onRepair;
  final VoidCallback onContract;
  const _MaintenanceCard({
    required this.listing,
    required this.onRepair,
    required this.onContract,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contract = listing.contract;
    return MarketplaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MosqueLine(
            mosque: listing.mosque,
            icon: Icons.build_rounded,
            subtitle: listing.mosque.address,
          ),
          const SizedBox(height: 14),
          TextCustom(
            text: listing.description,
            fontSize: 14,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 14),
          ButtonCustom.primary(
            text: '${l10n.payRepair} • ${l10n.priceKwd(listing.repairPrice)}',
            onPressed: onRepair,
          ),
          if (contract != null) ...[
            const SizedBox(height: 8),
            ButtonCustom.secondary(
              text:
                  '${l10n.maintenanceContract} • ${l10n.priceKwd(contract.price)}',
              onPressed: onContract,
            ),
          ],
        ],
      ),
    );
  }
}

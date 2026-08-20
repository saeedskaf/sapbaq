import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';
import 'package:sapbaq/features/marketplace/presentation/bloc/marketplace_cubit.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/marketplace_card.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/water_purchase.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

class WaterTab extends StatefulWidget {
  const WaterTab({super.key});

  @override
  State<WaterTab> createState() => _WaterTabState();
}

class _WaterTabState extends State<WaterTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<MarketplaceCubit>();
    if (cubit.state.waterStatus == LoadStatus.initial) cubit.loadWater();
  }

  void _reload() => context.read<MarketplaceCubit>().loadWater();
  Future<void> _reloadFuture() async => _reload();

  void _buy(WaterListing listing) =>
      startWaterPurchase(context, listing, reload: _reload);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      buildWhen: (a, b) => a.waterStatus != b.waterStatus || a.water != b.water,
      builder: (context, state) {
        switch (state.waterStatus) {
          case LoadStatus.initial:
          case LoadStatus.loading:
            return const LoadingView();
          case LoadStatus.failure:
            return ErrorView(
              message: state.waterError ?? l10n.comingSoon,
              retryLabel: l10n.retry,
              onRetry: _reload,
            );
          case LoadStatus.success:
            if (state.water.isEmpty) {
              return EmptyView(
                message: l10n.emptyWater,
                icon: Icons.water_drop_outlined,
              );
            }
            return RefreshIndicator(
              color: context.colors.primary,
              onRefresh: _reloadFuture,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.water.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _WaterCard(listing: state.water[i], onBuy: _buy),
              ),
            );
        }
      },
    );
  }
}

class _WaterCard extends StatelessWidget {
  final WaterListing listing;
  final void Function(WaterListing) onBuy;
  const _WaterCard({required this.listing, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cap = listing.cap;
    return MarketplaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MosqueLine(mosque: listing.mosque, icon: Icons.water_drop_rounded),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextCustom(
                  text: listing.package.label,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextCustom(
                text: l10n.priceKwd(listing.package.price),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.colors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: cap.progress,
              minHeight: 8,
              backgroundColor: context.colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(context.colors.primary),
            ),
          ),
          const SizedBox(height: 6),
          TextCustom(
            text: l10n.waterFunded(cap.funded, cap.max),
            fontSize: 12,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 12),
          ButtonCustom.primary(
            text: l10n.contribute,
            icon: const Icon(Icons.volunteer_activism_rounded, size: 20),
            onPressed: () => onBuy(listing),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_button.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/widgets/product_thumb.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';
import 'package:sapbaq/features/marketplace/presentation/bloc/marketplace_cubit.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/equipment_contribute.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/equipment_model_sheet.dart';
import 'package:sapbaq/features/marketplace/presentation/widgets/marketplace_card.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// Equipment campaigns: several donors each fund part of one unit's goal until
/// it's met, then a single unit is installed and every contribution settles
/// together (FLUTTER_EQUIPMENT_CROWDFUNDING). The model is fixed by the regional
/// manager at approval — this screen never picks one.
class EquipmentTab extends StatefulWidget {
  const EquipmentTab({super.key});

  @override
  State<EquipmentTab> createState() => _EquipmentTabState();
}

class _EquipmentTabState extends State<EquipmentTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<MarketplaceCubit>();
    if (cubit.state.equipmentStatus == LoadStatus.initial) {
      cubit.loadEquipment();
    }
  }

  void _reload() => context.read<MarketplaceCubit>().loadEquipment();
  Future<void> _reloadFuture() async => _reload();

  Future<void> _contribute(EquipmentListing listing) =>
      startEquipmentContribution(context, listing, reload: _reload);

  /// The combination is settled, so its sheet is a look at what's being funded
  /// — the gallery and specs — with the same contribute action at the bottom.
  Future<void> _openModel(EquipmentListing listing) async {
    if (listing.variant == null) return;
    final contribute = await showEquipmentModelSheet(context, listing: listing);
    if (contribute && mounted) await _contribute(listing);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      buildWhen: (a, b) =>
          a.equipmentStatus != b.equipmentStatus || a.equipment != b.equipment,
      builder: (context, state) {
        switch (state.equipmentStatus) {
          case LoadStatus.initial:
          case LoadStatus.loading:
            return const LoadingView();
          case LoadStatus.failure:
            return ErrorView(
              message: state.equipmentError ?? l10n.comingSoon,
              retryLabel: l10n.retry,
              onRetry: _reload,
            );
          case LoadStatus.success:
            // A row with no model or no goal can't be funded yet (an approval
            // from before crowdfunding shipped) — the server hides those, and
            // so do we rather than render a campaign with nothing to give.
            final campaigns = state.equipment
                .where((e) => e.isFundable)
                .toList();
            if (campaigns.isEmpty) {
              return EmptyView(
                message: l10n.emptyEquipment,
                icon: Icons.kitchen_outlined,
              );
            }
            return RefreshIndicator(
              color: context.colors.primary,
              onRefresh: _reloadFuture,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: campaigns.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _CampaignCard(
                  listing: campaigns[i],
                  onContribute: () => _contribute(campaigns[i]),
                  onOpenModel: () => _openModel(campaigns[i]),
                ),
              ),
            );
        }
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final EquipmentListing listing;
  final VoidCallback onContribute;
  final VoidCallback onOpenModel;

  const _CampaignCard({
    required this.listing,
    required this.onContribute,
    required this.onOpenModel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final funding = listing.funding!;
    return MarketplaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MosqueLine(mosque: listing.mosque, icon: Icons.kitchen_rounded),
          const SizedBox(height: 12),
          // The unit itself, tappable for the gallery and specs — the donor
          // reads what the mosque is getting, they no longer choose it.
          InkWell(
            onTap: onOpenModel,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                ProductThumb(
                  url: listing.variant!.image,
                  size: 56,
                  radius: 12,
                  placeholderIcon: Icons.kitchen_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextCustom(
                        text: listing.title,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextCustom(
                          text: listing.equipmentType,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.textHint,
                ),
              ],
            ),
          ),
          if (listing.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            TextCustom(
              text: listing.note,
              fontSize: 13,
              color: context.colors.textSecondary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          FundingProgress(funding: funding),
          const SizedBox(height: 14),
          ButtonCustom.primary(
            text: l10n.contributeAction,
            icon: const Icon(Icons.volunteer_activism_rounded, size: 20),
            onPressed: onContribute,
          ),
        ],
      ),
    );
  }
}

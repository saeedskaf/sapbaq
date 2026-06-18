import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq_admin/app/router/app_routes.dart';
import 'package:sapbaq_admin/core/bloc/load_status.dart';
import 'package:sapbaq_admin/core/theme/colors_custom.dart';
import 'package:sapbaq_admin/core/widgets/custom_text.dart';
import 'package:sapbaq_admin/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq_admin/core/widgets/state_views.dart';
import 'package:sapbaq_admin/features/driver/data/driver_repository.dart';
import 'package:sapbaq_admin/features/driver/presentation/bloc/driver_destinations_cubit.dart';
import 'package:sapbaq_admin/features/driver/presentation/widgets/driver_destination_card.dart';
import 'package:sapbaq_admin/features/shared/presentation/filter_tabs.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

class DriverDestinationsScreen extends StatelessWidget {
  const DriverDestinationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DriverDestinationsCubit(context.read<DriverRepository>())..load(),
      child: const _DriverDestinationsView(),
    );
  }
}

class _DriverDestinationsView extends StatefulWidget {
  const _DriverDestinationsView();

  @override
  State<_DriverDestinationsView> createState() =>
      _DriverDestinationsViewState();
}

class _DriverDestinationsViewState extends State<_DriverDestinationsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      context.read<DriverDestinationsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabLabels = [
      l10n.tabNew,
      l10n.tabAccepted,
      l10n.tabInDelivery,
      l10n.tabCompleted,
    ];

    return Scaffold(
      appBar: AppBar(
        title: TextCustom.subheading(text: l10n.driverDeliveriesTitle),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          BlocSelector<DriverDestinationsCubit, DriverDestinationsState,
              DriverTab>(
            selector: (state) => state.tab,
            builder: (context, tab) => FilterTabs(
              labels: tabLabels,
              selectedIndex: DriverTab.values.indexOf(tab),
              onChanged: (i) => context
                  .read<DriverDestinationsCubit>()
                  .setTab(DriverTab.values[i]),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<DriverDestinationsCubit,
                DriverDestinationsState>(
              builder: (context, state) {
                if (state.status == LoadStatus.loading) {
                  return const LoadingView();
                }
                if (state.status == LoadStatus.failure) {
                  return ErrorView(
                    message: state.message ?? l10n.genericError,
                    retryLabel: l10n.retry,
                    onRetry: () => context.read<DriverDestinationsCubit>().load(),
                  );
                }
                final visible = state.visible;
                if (visible.isEmpty) {
                  return RefreshIndicator(
                    color: ColorsCustom.primary,
                    onRefresh: () =>
                        context.read<DriverDestinationsCubit>().load(),
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: EmptyView(
                            message: l10n.emptyDeliveries,
                            icon: Icons.local_shipping_outlined,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: ColorsCustom.primary,
                  onRefresh: () =>
                      context.read<DriverDestinationsCubit>().load(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      floatingNavBarClearance(context),
                    ),
                    itemCount: visible.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= visible.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: ColorsCustom.primary,
                            ),
                          ),
                        );
                      }
                      final dest = visible[i];
                      return DriverDestinationCard(
                        destination: dest,
                        onTap: () async {
                          await context.pushNamed(
                            AppRoutes.driverDestinationName,
                            pathParameters: {'id': '${dest.id}'},
                          );
                          // Refresh on return — status may have changed.
                          if (context.mounted) {
                            context.read<DriverDestinationsCubit>().load();
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

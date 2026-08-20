import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sapbaq/app/router/app_routes.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/core/auth/auth_guard.dart';
import 'package:sapbaq/core/widgets/floating_nav_bar.dart';
import 'package:sapbaq/core/widgets/state_views.dart';
import 'package:sapbaq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sapbaq/features/orders/data/models/activity.dart';
import 'package:sapbaq/features/orders/data/orders_repository.dart';
import 'package:sapbaq/features/orders/presentation/bloc/activity_cubit.dart';
import 'package:sapbaq/features/orders/presentation/widgets/activity_card.dart';
import 'package:sapbaq/l10n/app_localizations.dart';

/// «طلباتي» — **one list for everything the donor has done**: product orders,
/// equipment requests and marketplace contributions, newest first with whatever
/// still needs them at the top.
///
/// No tabs and no filters, by decision: the split between «طلباتي» and
/// «مساهماتي» meant a donor had to know which of two screens held what they
/// paid for. The card carries the distinction instead, and the server's
/// ordering (`ACTION_REQUIRED` first) is what surfaces the unpaid ones.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Guests have no history and the feed is auth-only — show a sign-in prompt
    // rather than a list that would 401.
    final isGuest = context.watch<AuthBloc>().state.status == AuthStatus.guest;
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(title: TextCustom.subheading(text: l10n.ordersTitle)),
        body: GuestGateView(
          title: l10n.loginRequiredTitle,
          message: l10n.guestOrdersMessage,
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          ActivityCubit(context.read<OrdersRepository>())..load(),
      child: const _ActivityView(),
    );
  }
}

class _ActivityView extends StatefulWidget {
  const _ActivityView();

  @override
  State<_ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<_ActivityView> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 240) {
      context.read<ActivityCubit>().loadMore();
    }
  }

  /// Opens the row's own detail screen — the three kept their endpoints, so the
  /// feed only says which one to open — then refreshes on the way back: paying
  /// happens over there, and a row that still reads «ادفع الآن» after the money
  /// landed is the worst thing this list can say.
  Future<void> _open(ActivityRow row) async {
    final link = row.deepLink;
    if (link == null) return;
    switch (link.route) {
      case 'order':
        await context.pushNamed(
          AppRoutes.orderDetailName,
          pathParameters: {'id': '${link.id}'},
        );
      case 'contribution':
        await context.pushNamed(
          AppRoutes.contributionDetailName,
          pathParameters: {'id': '${link.id}'},
        );
      case 'equipment_request':
        await context.pushNamed(
          AppRoutes.equipmentRequestsName,
          queryParameters: {'request': '${link.id}'},
        );
      default:
        return;
    }
    if (!mounted) return;
    context.read<ActivityCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: TextCustom.subheading(text: l10n.ordersTitle)),
      body: BlocBuilder<ActivityCubit, ActivityState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const _SkeletonList();
            case LoadStatus.failure:
              return ErrorView(
                message: state.message ?? l10n.comingSoon,
                retryLabel: l10n.retry,
                onRetry: () => context.read<ActivityCubit>().load(),
              );
            case LoadStatus.success:
              if (state.rows.isEmpty) {
                return RefreshIndicator(
                  color: context.colors.primary,
                  onRefresh: () => context.read<ActivityCubit>().refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: floatingNavBarClearance(context),
                    ),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.6,
                        child: EmptyView(
                          message: l10n.emptyOrders,
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: context.colors.primary,
                onRefresh: () => context.read<ActivityCubit>().refresh(),
                child: ListView.separated(
                  controller: _controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Clear the floating nav bar *and* the cart bar above it —
                  // this reads the shell's reservation, so the last card stops
                  // hiding the moment a cart appears.
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    floatingNavBarClearance(context),
                  ),
                  itemCount: state.rows.length + (state.loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i >= state.rows.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      );
                    }
                    final row = state.rows[i];
                    return ActivityCard(
                      row: row,
                      onTap: () => _open(row),
                      // Paying happens on the detail screen, which owns the
                      // gateway flow for each kind; the card is the shortcut.
                      onAction: () => _open(row),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}

/// First-load placeholder: a pulsing sketch of the feed's real rhythm instead
/// of a lone spinner — same treatment as the media gallery's skeleton.
class _SkeletonList extends StatefulWidget {
  const _SkeletonList();

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: 0.45,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulse,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          // Tracks the real card's shortest form (thumbnail + chip + title +
          // receipt line). Cards vary with the subtitle and mosque lines, so
          // this is the floor rather than an average — undershooting it is
          // what makes the list visibly jump when the feed lands.
          height: 116,
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
